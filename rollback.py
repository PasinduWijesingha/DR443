import socket
import time
import smtplib # Add SMTP code to send an email after successful rollback.
import os
from netmiko import ConnectHandler

ip_address = "172.21.10.156" 

while(True):

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('172.21.10.156',443)) 
    
    if result == 0:

        print ("Open Port")
        time.sleep(600)

        os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.21.10.156")
       
        os.system("python3.7 hq_backup_restore.py")

        os.system("python3.7 device_registration_from_dr_to_hq.py")

        os.system("python3.7 hq_cronjob_service_start.py")

        os.system("python3.7 harmony_failover.py")

    else:

        print ("Close Port")   
        time.sleep(600)

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('172.21.10.156',443)) 

        if result == 0:
            print ("Open Port")
            time.sleep(300)

            os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.21.10.156")
           
	 	os.system("python3.7 hq_backup_restore.py")

        	os.system("python3.7 device_registration_from_dr_to_hq.py")

        	os.system("python3.7 hq_cronjob_service_start.py")

        	os.system("python3.7 harmony_failover.py")
          
    	  else:

        	print ("Close Port")   
        	time.sleep(300)

       	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        	result = sock.connect_ex(('172.21.10.156',443)) 
        	
		if result == 0:
                print ("Open Port")
                time.sleep(150)

           	    os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.28.254.60")
                   
        	    os.system("python3.7 hq_backup_restore.py")

       	    os.system("python3.7 device_registration_from_dr_to_hq.py")

       	    os.system("python3.7 hq_cronjob_service_start.py")

        	    os.system("python3.7 harmony_failover.py")   
          
    	      else:

        	    print ("Close Port")   
                time.sleep(150)
               
time.sleep(3)
sock.close()