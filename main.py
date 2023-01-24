import socket
import time
import subprocess
import os

ip_address = "172.21.10.57" # change the IP 
while(True):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('172.21.10.57',9999)) # change the IP and port
    if result == 0:
        print ("Open Port")
    else:
        print ("Close Port")
        cmd = 'echo "Hello world"' # change the command as you want 
        os.system(cmd)
        break
        

    time.sleep(3)
    sock.close()