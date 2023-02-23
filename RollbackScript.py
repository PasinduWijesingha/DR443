import socket
import time
import smtplib
import os
from netmiko import ConnectHandler

ip_address = "172.21.10.156" # change the IP 
while(True):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('172.21.10.156',443)) # change the IP and port
    
    if result == 0:
        print ("Open Port")
        time.sleep(600)
        os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.28.254.60")
       
        os.system("python3.7 a10rollback.py")

        os.system("python3.7 a10_pr_device.py")

        os.system("python3.7 hq_Cronjob_starting.py")

        os.system("python DR443.py")
    else:
        print ("Close Port")   
        time.sleep(600)

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('172.21.10.156',443)) # change the IP and port
        if result == 0:
            print ("Open Port")
            time.sleep(300)
            os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.28.254.60")
           
            os.system("python3.7 a10rollback.py")
    
            os.system("python3.7 a10_pr_device.py")
    
            os.system("python3.7 hq_Cronjob_starting.py")
    
            os.system("python DR443.py")
        else:
            print ("Close Port")   
            time.sleep(300)

            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('172.21.10.156',443)) # change the IP and port
            if result == 0:
                print ("Open Port")
                time.sleep(150)
                    os.system("/harmony_backup.sh --metricsa=no --auth=passwordless --remotelocation=/a10harmony --remoteuser=root --remotehost=172.28.254.60")
                   
                    os.system("python3.7 a10rollback.py")
            
                    os.system("python3.7 a10_pr_device.py")
            
                    os.system("python3.7 hq_Cronjob_starting.py")
            
                    os.system("python DR443.py")
            else:
                print ("Close Port")   
                time.sleep(150)
               
time.sleep(3)
sock.close()