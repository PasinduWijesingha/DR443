#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
  echo "*** You have forcibly terminated the restore process ***" | tee -a ${LOG_PATH}/${log_file}
if ! [[ -z ${spin_pid} ]];then
  stop_progress ${spin_pid};
fi
exit 1
}

THIS_ROOT=$(readlink -f $(dirname "${BASH_SOURCE}"))
SRC_ROOT=$(readlink -f ${THIS_ROOT}/..)
JQ=$(readlink -f "${SRC_ROOT}/jq")
LOG_PATH="/a10harmony/logs/harmony-restore"
log_file=$(date +"harmony-restore-%Y-%m-%d-%H-%M.log")
export LOG_FILE_PATH="${LOG_PATH}/${log_file}"
mkdir -p ${LOG_PATH}

# get deployment path
deployment_path=$( kubectl get cm deployment-path -o=jsonpath={.data.'deployment_path'} )
type_of_cluster=$( kubectl get cm cluster-type -o=jsonpath={.data.'cluster-type'} )
componets_to_check=(EDGE BARISTA)

source ${SRC_ROOT}/common.sh
source ${SRC_ROOT}/util.sh
source ${SRC_ROOT}/controller-utils.sh

if [[ $(whoami) != "root" ]]; then
    echo "You must be root user to run this script"
    exit 1
fi

function verify_checksum {
    local backupfilepath=$1
    local pod_name=$2
    local md5file=$(echo $backupfilepath | sed -e "s/.tar.gz/.md5/")
    local checksum=$(cat  $md5file | grep -v "HC-version" )
    local filechecksum=$(md5sum ${backupfilepath}| awk -F" " '{print $1}')

    if [[ ${filechecksum} != ${checksum} ]];then
        redirect_to_terminal "checksum does not match for ${pod_name} and ${backupfilepath}" "-u"
        stop_progress ${spin_pid};
        exit 1
    fi
}

function check_value {
    if ! [[ -f "$2" ]]; then
        redirect_to_terminal "Backup file $2 doesnot exist for pod $1. exiting from restore..." "-u"
        exit 1
    fi
}

function get_latest_backup {
    local backuppath=$2
    local component=$1
    local file_name=$(ls -ltA ${backuppath}/${component}/*.tar.gz  | head -1 | awk -F" " '{print $9}')
    echo "$file_name"
}

function command_status {
    if [[ $1 -eq 0 ]]; then
        redirect_to_logs "$2 is successfull" "-u"
    else
        redirect_to_terminal "Error occured while $2" "-u"
        stop_progress ${spin_pid};
        exit 1
    fi
}

function usage {
echo "
This script restore harmony . You can restore in single click or give specific backupfile name of each component. Examples are given below.
Below arguments are supported.

--configds0 :           Path of config-datastore-0 backup file.
--configds1 :           Path of config-datastore-1 backup file.
--configds2 :           Path of config-datastore-2 backup file.
--datastore :           path of the datastore-connnetor backup file.
--elm :                 Path of elm backup file.
--remotehost:           192.168.10.10
--remotelocation:       Remote location of the harmony_backup dir
--localpath:            Path of backup of directory, applicable only for config datastore restore.
                        default value in single node is /a10harmony/harmony_backup
                        default value in multi node is /a10cvol/cfs/data/harmony_backup
--remoteuser:           admin (rsync user).
--s3bucketpath:         Object URL of harmony backup tar from s3.
--auth:                 passwordless|aws
--metrics:              Takes yes/no. default is yes.
--selectiverestore:     Takes true/false. default value is false. you need to give true , if you are restoring from specific backup file
                        It is recommended to do selective restore if you are resotring from HC version older then 5.0.0
--metricssnapshot:      metrics snapshot name. default value is esharmony
--migration:            path of the migration script to be executed inside config-datastore-0 pod

Example 1: When backup is available on remote host.
          $0  --remoteuser=admin --remotehost=192.168.10.10 --remotelocation=/home/admin/ --auth=passwordless

Example 2: When backup is available on remote host and do not want to restore elasticsearch.
          $0  --remoteuser=admin --remotehost=192.168.10.10 --remotelocation=/home/admin/ --metrics=no --auth=passwordless

Example 3: local restore
          $0

Example 4: local restore without elasticsearch restore
          $0 --metrics=no

Example 5: restore from specific backup file.
          $0 --selectiverestore='true' --configds0=/home/admin/harmony_backup/config-datastore-0/cds0.tar.gz --metricsdatastore='esharmony_2019-01-24-16:00:01'

Example 6: restore from specific backup file (without metrics).
          $0 --selectiverestore='true' --configds0=/home/admin/harmony_backup/config-datastore-0/cds0.tar.gz --metrics=no
"
}


while [ "$1" != "" ]; do
    PARAM=$(echo $1 | awk -F= '{print $1}')
    VALUE=$(echo $1 | awk -F= '{print $2}')
    case $PARAM in
        -h | --help)
            usage
            exit 1
            ;;
        --backuppath)
            BACKUPPATH=$VALUE
            ;;
        --configds0)
            CONFIGDS0BACKUP=$VALUE
            ;;
        --configds1)
            CONFIGDS1BACKUP=$VALUE
            ;;
        --configds2)
            CONFIGDS2BACKUP=$VALUE
            ;;
        --datastore)
            DATASTORECN=$VALUE
            ;;
        --elm)
            ELMBACKUP=$VALUE
            ;;
        --remotehost)
            REMOTEHOST=$VALUE
            ;;
        --remoteuser)
            REMOTEUSER=$VALUE
            ;;
        --remotelocation)
            REMOTELOCATION=$VALUE
            REMOTELOCATION="$REMOTELOCATION/harmony_backup"
            ;;
        --auth)
            AUTHTYPE=$VALUE
            ;;
        --s3bucketpath)
            S3BUCKETPATH=$VALUE
            ;;
       --metrics)
            ANALYTICSRESTORE=$VALUE
            ;;
       --selectiverestore)
            SELECTIVE_RESTORE=$VALUE
            ;;
       --metricssnapshot)
            SNAPSHOTNAME=$VALUE
            ;;
       --localpath)
            HCBACKUP_PATH=$VALUE
            HCROOT_PATH=$( dirname ${HCBACKUP_PATH})
            ;;
      --accesskeypath)
            KEYPATH=$VALUE
            ;;
      --migration)
            script_path=$VALUE
            ;;
        *)
            redirect_to_terminal "ERROR: unknown parameter \"$PARAM\" " "-u"
            usage
            exit 1
            ;;
    esac
    shift
done


ES_REPOSITORY="${ES_REPOSITORY:-esharmony}"
ANALYTICSRESTORE="${ANALYTICSRESTORE:-yes}"
SELECTIVE_RESTORE="${SELECTIVE_RESTORE:-false}"
SNAPSHOTNAME="${SNAPSHOTNAME:-esharmony}"
export CONTROLLER_READY_TIMEOUT=1200
DS_DATA_PATH="/cfs/data/dsc" #datastore restore path inside pod
if [[ ${type_of_cluster} -ne 1 ]];then
    HCROOT_PATH="${HCROOT_PATH:-/a10cvol/cfs/data/}"
    REMOTELOCATION="${REMOTELOCATION:-/a10cvol/cfs/data/harmony_backup}"
else
    HCROOT_PATH="${HCROOT_PATH:-/a10harmony}"
    REMOTELOCATION="${REMOTELOCATION:-/a10harmony/harmony_backup}"
fi
HCBACKUP_PATH="${HCROOT_PATH}/harmony_backup"
ESBACKUP_PATH="${HCROOT_PATH}/harmony_backup/esbackup}"


redirect_to_logs  "########### script started at $(date -u '+%Y-%m-%d-%H-%M') ##########" "-u"
redirect_to_terminal "logs will be written to  ${LOG_FILE_PATH}" "-u"

#put check to aviod remote restore for selective restore
if [[ ${SELECTIVE_RESTORE} = "true" && -n ${AUTHTYPE} ]];then
    echo
    redirect_to_terminal "selective restore is not supported for remote backup." "-u"
    redirect_to_terminal "Please download the backup files to the local system and perform the selective restore" "-u"
    echo
    exit 1
fi

#put check to avoid partial restore
if [[ ${type_of_cluster} = 1 && ${SELECTIVE_RESTORE} = "true" ]]; then
    if [[ -z $CONFIGDS0BACKUP ]]; then
        redirect_to_terminal "You are trying to run partial restore, please provide the absolute path to the config datastore backupfile." "-u"
        exit 1
    fi
elif [[ ${type_of_cluster} = 3 && ${SELECTIVE_RESTORE} = "true" ]]; then
    if [[ -z $CONFIGDS0BACKUP  ||  -z $CONFIGDS1BACKUP ||  -z $CONFIGDS2BACKUP ]]; then
        redirect_to_terminal "You are trying to run partial restore, please provide the absolute path to the config datastore backupfiles" "-u"
        exit 1
    fi
fi

redirect_to_terminal "wait if scheduled harmony backup is in progress" "-u"
progress 10 & spin_pid=$!
check_for_harmony_backup
if [[ $? -ne 0 ]];then
    redirect_to_terminal "scheduled Harmony backup took longer time than expected exiting..." "-u"
    redirect_to_terminal "please re-initiate restore after Harmony backup is completed" "-u"
    stop_progress ${spin_pid};
    exit 1
fi
stop_progress ${spin_pid};

if [[ -n ${REMOTEHOST} ]];then
    ipcalc -6 ${REMOTEHOST} &>> /dev/null
    if [[ $? -eq 0 ]];then
        REMOTE_HOST_IP="[${REMOTEHOST}]"
    else
        REMOTE_HOST_IP=${REMOTEHOST}
    fi
fi

if [[ -n ${AUTHTYPE} && ${AUTHTYPE} != "aws" ]]; then
    if [[ -n ${REMOTEHOST} && -n ${REMOTEUSER} && -n ${REMOTELOCATION} ]]; then
        redirect_to_logs "syncing backup from remote location, this may take several minutes.." "-u"
        progress 10 & spin_pid=$!
        if [[ ${AUTHTYPE} = "passwordless" &&  ${ANALYTICSRESTORE} = "yes" ]]; then
            #rsync from remote dir
            rsync -azvhe 'ssh -o StrictHostKeyChecking=no' ${REMOTEUSER}@${REMOTE_HOST_IP}:${REMOTELOCATION} ${HCROOT_PATH}  --delete-after
            command_status $? "rsync"
            stop_progress ${spin_pid};
        elif [[ ${AUTHTYPE} = "passwordless" &&  ${ANALYTICSRESTORE} = "no" ]]; then
            #rsync from remote location excluding elasticsearch
            rsync -azvhe 'ssh -o StrictHostKeyChecking=no' ${REMOTEUSER}@${REMOTE_HOST_IP}:${REMOTELOCATION} --exclude 'elasticsearch' ${HCROOT_PATH} --delete-after
            command_status $? "rsync"
            stop_progress ${spin_pid};
        elif [[ ${AUTHTYPE} = "keybased" &&  ${ANALYTICSRESTORE} = "yes" ]]; then
            #rsync with ssh key
            rsync -azvhe "ssh -i ${KEYPATH} -o StrictHostKeyChecking=no " ${REMOTEUSER}@${REMOTE_HOST_IP}:${REMOTELOCATION} ${HCROOT_PATH} --delete-after
            command_status $? "rsync"
            stop_progress ${spin_pid};
        elif [[ ${AUTHTYPE} = "keybased" &&  ${ANALYTICSRESTORE} = "no" ]]; then
            rsync  -azvhe "ssh -i ${KEYPATH} -o StrictHostKeyChecking=no" ${REMOTEUSER}@${REMOTE_HOST_IP}:${REMOTELOCATION} --exclude 'elasticsearch' ${HCROOT_PATH}
            command_status $? "rsync"
            stop_progress ${spin_pid};
        fi
    else
        redirect_to_terminal "remote host, remote user and remote location are manadatory parameters !!!!!" "-u"
        exit 1
    fi
elif [[ -n ${AUTHTYPE} && ${AUTHTYPE} == "aws" ]]; then
    redirect_to_logs "Initiating restore from AWS S3" "-u"
    if [[ -n ${S3BUCKETPATH} ]]; then
        curl ${S3BUCKETPATH} -o /tmp/harmonybackup.tar.gz
        if [[ -d /tmp/hc_restore ]]; then
            rm -rf /tmp/hc_restore
            mkdir -p /tmp/hc_restore
            tar xf /tmp/harmonybackup.tar.gz -C /tmp/hc_restore --strip-components=1
        fi
    else
        redirect_to_terminal "AWS S3 bucket path is mandatory parameter for restoring from aws" "-u"
        exit 1
    fi
else
    redirect_to_terminal "Initiating restore from local backup " "-u"
fi

if [[ ${type_of_cluster} = 1 ]]; then
    redirect_to_terminal "This is 1 node cluster" "-u"
    if [[ -z ${CONFIGDS0BACKUP} ]]; then
        # check CONFIGDS0BACKUP variable has value or not. if not then get it
        redirect_to_terminal "Getting the latest backup file from the default location ${HCBACKUP_PATH} for config-datastore " "-u"
        latest_backup=$(get_latest_backup "config-datastore-0" ${HCBACKUP_PATH})
        check_value "config-datastore-0" ${latest_backup}
        CONFIGDS0BACKUP="${latest_backup}"
        redirect_to_terminal "$(basename ${CONFIGDS0BACKUP}) is the latest backup file for config-datastore-0 ..." "-u"
    fi
elif [[ ${type_of_cluster} = 3 ]]; then
    redirect_to_terminal "This is 3 node cluster" "-u"
    if [[ -z ${CONFIGDS0BACKUP} && -z ${CONFIGDS1BACKUP} && -z ${CONFIGDS2BACKUP} ]]; then
        redirect_to_terminal "Getting the latest backup file from the default location ${HCBACKUP_PATH}/harmony_backup for config-datastore " "-u"
        latest_backup=$(get_latest_backup "config-datastore-0" ${HCBACKUP_PATH} )
        check_value "config-datastore-0" ${latest_backup}
        CONFIGDS0BACKUP="${latest_backup}"
        redirect_to_terminal "$(basename ${CONFIGDS0BACKUP}) is latest backupfile for config-datastore-0  ..." "-u"
        unset latest_backup
        latest_backup=$(get_latest_backup "config-datastore-1" ${HCBACKUP_PATH} )
        check_value "config-datastore-1" ${latest_backup}
        CONFIGDS1BACKUP="${latest_backup}"
        redirect_to_terminal "$(basename ${CONFIGDS1BACKUP}) is latest backupfile for config-datastore-1  ..." "-u"
        unset latest_backup
        latest_backup=$(get_latest_backup  "config-datastore-2" ${HCBACKUP_PATH})
        check_value  "config-datastore-2" ${latest_backup}
        CONFIGDS2BACKUP="${latest_backup}"
        redirect_to_terminal "$(basename ${CONFIGDS2BACKUP}) is latest backupfile for config-datastore-2  ..." "-u"
    fi
fi


if [[ ${SELECTIVE_RESTORE} != "true" ]]; then
    for ((i=0;i<${type_of_cluster};i++))
    do
        ckfile=CONFIGDS${i}BACKUP
        verify_checksum ${!ckfile} "config-datastore-${i}"
    done
fi

# Either the md5file of backup is not preset or version parameter is not set or if it upgrade
# Then assume the backup version is older version then 5.0.0
#set backup version
md5file=$(echo ${CONFIGDS0BACKUP} | sed -e "s/.tar.gz/.md5/" )
if [[ -f ${md5file} ]]; then
    version=$(cat ${md5file} | grep "HC-version" | cut -f2 -d"=")
    if [[ -z ${version} ]];then
        version="4.2.1"
    fi
else
    version="4.2.1"
fi

#validate the for datastore seletive restore if HC version if greater then 5.0.0
if [[ $(echo ${version} | sed -e 's/\.//g' | cut -b 1-3) -ge 500  ]] && [[ ${SELECTIVE_RESTORE} == "true" ]];then
     if [[ -z ${DATASTORECN} ]] || ! [[ -f ${DATASTORECN} ]];then
         redirect_to_terminal "You are trying to run partial restore for ${version}, please provide the absolute path to the datastore connector backupfile." "-u"
         exit 1
     fi
fi

#validate the for elm seletive restore if HC version if greater then 5.2.0
if [[ $(echo ${version} | sed -e 's/\.//g' | cut -b 1-3) -ge 520  ]] && [[ ${SELECTIVE_RESTORE} == "true" ]];then
     if [[ -z ${ELMBACKUP} ]] || ! [[ -f ${ELMBACKUP} ]];then
         redirect_to_terminal "You are trying to run partial restore for ${version}, please provide the absolute path to the elm datastore backupfile." "-u"
         exit 1
     fi
fi


#Copying Datastore backup file to pod
if [[ ${version} != 4.2.1 ]];then
    datastorePod=$(sudo kubectl get pod -l app=datastore-connector -o jsonpath={.items[].metadata.name})
    if [[ -z $DATASTORECN ]];then
        redirect_to_terminal "Getting the latest backup file from the default location ${HCBACKUP_PATH} for datastore-connector " "-u"
        unset latest_backup
        latest_backup=$(get_latest_backup  "datastore-connector" ${HCBACKUP_PATH})
        check_value  "datastore-connector" ${latest_backup}
        DATASTORECN=${latest_backup}
    fi
    sudo kubectl exec -it ${datastorePod} -- bash -c "rm -rf ${DS_DATA_PATH}/*"
    ds_bkp_fil_name=$(basename $DATASTORECN)
    sudo kubectl cp $DATASTORECN ${datastorePod}:${DS_DATA_PATH}/${ds_bkp_fil_name}
    redirect_to_terminal "Initiating Datastore connector restore" "-u"
    unset spin_pid
    progress 10 & spin_pid=$!
    sudo kubectl exec -it ${datastorePod} -- bash -c "cd ${DS_DATA_PATH}; tar xvpf  ${ds_bkp_fil_name}" &>> ${LOG_FILE_PATH}
    if [[ $? -ne 0 ]]; then
        redirect_to_terminal "Restore failed for  Datastore connector " "-u"
        stop_progress ${spin_pid};
        exit 1
    else
        redirect_to_terminal "Datastore connector restored sucessfully" "-u"
        sudo kubectl exec -it ${datastorePod} -- bash -c "rm -f ${DS_DATA_PATH}/${ds_bkp_fil_name}"
        stop_progress ${spin_pid};
    fi
fi


#Copying ELM backup file to pod and restore
if [[ $(echo ${version} | sed -e 's/\.//g' | cut -b 1-3) -ge 520 ]];then
    elmPod=$(sudo kubectl get pod -l app="elm-web",tier=app -o jsonpath={.items[].metadata.name})
    if [[ -z $ELMBACKUP ]];then
        redirect_to_terminal "Getting the latest backup file from the default location ${HCBACKUP_PATH} for elm DB" "-u"
        unset latest_backup
        latest_backup=$(get_latest_backup  "elm" ${HCBACKUP_PATH})
        check_value  "elm" ${latest_backup}
        ELMBACKUP=${latest_backup}
    fi
    sudo kubectl exec -it ${elmPod} -- /bin/sh -c "rm -rf /app/tmp/elm-back*.tar.gz"
    bkp_fil_name=$(basename $ELMBACKUP)
    sudo kubectl cp $ELMBACKUP ${elmPod}:/app/tmp/${bkp_fil_name}
    redirect_to_terminal "Initiating ELM DB restore" "-u"
    unset spin_pid
    progress 10 & spin_pid=$!
    sudo kubectl exec -it ${elmPod} -- /bin/sh -c "/app/bin/restore-db.sh -f /app/tmp/${bkp_fil_name}" &>> ${LOG_FILE_PATH}
    if [[ $? -ne 0 ]]; then
        redirect_to_terminal "Restore failed for  ELM " "-u"
        stop_progress ${spin_pid};
        exit 1
    else
        redirect_to_terminal "ELM DB restored sucessfully" "-u"
        sudo kubectl exec -it ${elmPod} -- /bin/sh -c "rm -f /app/tmp/${bkp_fil_name}"
        stop_progress ${spin_pid};
    fi
fi



redirect_to_terminal "Initiating Config datastore restore " "-u"
unset spin_pid
progress 10 & spin_pid=$!

if [[ ${type_of_cluster} -eq 1 ]]; then
    ${deployment_path}/utilities/onprem_restore_cds.sh --migration=${script_path} --backupversion=${version} --configds1backup=${CONFIGDS0BACKUP} >>  ${LOG_FILE_PATH}
    if [[ $? -eq 0 ]]; then
        stop_progress ${spin_pid};
        echo -ne "\t[Done]\n"
        redirect_to_terminal "Config datastore restore process completed successfully " "-u"
    else
        stop_progress ${spin_pid};
        echo -ne "\t[Failed]\n"
        redirect_to_terminal "!!!!!!!!!! Error ocurred in config-datastore restoration process" "-u"
        exit 1
    fi
else
    ${deployment_path}/utilities/onprem_restore_cds.sh --migration=${script_path} --backupversion=${version} --configds1backup=${CONFIGDS0BACKUP} --configds2backup=${CONFIGDS1BACKUP} --configds3backup=${CONFIGDS2BACKUP}  >> ${LOG_FILE_PATH}
    if [[ $? -eq 0 ]]; then
        stop_progress ${spin_pid};
        echo -ne "\t[Done]\n"
        redirect_to_terminal "Config datastore restore process completed successfully " "-u"
    else
        stop_progress ${spin_pid};
        echo -ne "\t[failed]\n"
        redirect_to_terminal " !!!!!!!!!! Error ocurred in config-datastore restoration process" "-u"
        exit 1
    fi
fi

for component in ${componets_to_check[@]}
do
    name=$(echo $component | awk '{print tolower($0)}')
    is-component-ready "${component}" "${name}" "${name}"
    if [[ $? -ne 0 ]];then
        redirect_to_terminal "[Error] Timedout while waiting for component ${name} to be ready" "-u"
        exit 1
    fi
done


if [[ $ANALYTICSRESTORE = "yes" ]]; then
    metrics=$(kubectl get cm hc-backup -o=jsonpath={.data."metrics"})
    if [[ ${metrics} == "yes" ]]; then
        redirect_to_terminal "Initiating elasticsearch restore for repo ${ES_REPOSITORY} from snapshot ${SNAPSHOTNAME} " "-u"
        unset spin_pid
        progress 10 & spin_pid=$!
        ${deployment_path}/utilities/esrestore.sh --reponame=${ES_REPOSITORY} --snapshotname=${SNAPSHOTNAME} >>  ${LOG_FILE_PATH}
        if [[ $? -eq 0 ]]; then
            stop_progress ${spin_pid};
            echo -ne "\t[Done]\n"
            redirect_to_terminal "elasticseach restore completed successfully " "-u"
        else
            stop_progress ${spin_pid};
            echo -ne "\t[Failed]\n"
            redirect_to_terminal "!!!!!!!!!!! Error ocurred in Elasticsearch restoration process, please refer log file ${LOG_FILE_PATH} " "-u"
            exit 1
        fi
    else
        redirect_to_terminal "Metrics backup is not enabled, skipping the metrics restore.." "-u"
    fi
fi


#restoring editable properties from cassandra.
redirect_to_terminal "Restoring user editable properties from cassandra... " "-u"
kubectl exec -it operatorconsole-0 --  python3.6 /opt/operatorconsole-1.0-SNAPSHOT/python_modules/restart_and_restore_components.py &>> ${LOG_FILE_PATH}
    if [[ $? -ne 0 ]];then
        redirect_to_terminal "Failed to restore user editable properties from cassandra.., Edit the values manually" "-u"
    fi
redirect_to_terminal "Editable properties restored completed successfully" "-u"

#uncomment harmony_backup if it is disabled on the node.
redirect_to_terminal "Enabling harmony backup cron if it is disabled" "-u"
crontab -l | sed '/harmony_backup/s/^#*//'  | crontab -

#updating current HC setup as primary
kubectl patch configmap/hc-backup --type merge -p '{"data":{"isPrimary":"True"}}' &>> ${LOG_FILE_PATH}
if [[ $? -ne 0 ]];then
    redirect_to_terminal "Failed to set isPrimary to True in hc-backup"
    exit 1
fi


redirect_to_terminal "Removing logs older then 30 days " "-u"
find ${LOG_PATH} -type f -mtime +30 | xargs rm -f &>> ${LOG_FILE_PATH}
