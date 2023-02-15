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
    else:
        print ("Close Port")   
        time.sleep(600)

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('172.21.10.156',443)) # change the IP and port
        if result == 0:
            print ("Open Port")
            time.sleep(300)
            continue
        else:
            print ("Close Port")   
            time.sleep(300)

            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('172.21.10.156',443)) # change the IP and port
            if result == 0:
                print ("Open Port")
                time.sleep(150)
                continue
            else:
                print ("Close Port")   
                time.sleep(150)
                # --------------------- After sussesful disaster this part will run -------------------------
                # try : 
                #     HarmonyController  = {
                #             "device_type": 'a10',
                #             "host": "172.21.10.156",
                #             "username": "root",
                #             "password": "P@ssw0rd@123",
                #         }

                #     # net_connect = ConnectHandler(**HarmonyController )
                #     # output = net_connect.send_command_timing("systemctl stop crond.service")

                #     # print(output)
                # except (ConnectionError, TypeError, NameError, SyntaxError ) as error:
                #         #net_connect.exit()
                #         print(error)
                
                #COMMAND NEED TO RUN
                cmd1 = './harmony_restore.sh --metrics=yes' # change the command as you want 
                cmd2 = 'python3.7 a10.py' # change the command as you want 

                os.system(cmd1)
                os.system(cmd2)

                try: 
                    #SEND YOUR MAIL
                    sender_email = "Sender Mail" #Add sender mail here
                    receiver_email = "Receiver Mail" #Add receiver mail here
                    password = "Enter Password" #Add your password
                    message = "Hello World !!!" #Add your massage here

                    server = smtplib.SMTP("smtp.office365.com", 587) # I add Example here please put correct SMTP server
                    server.starttls()
                    server.login(sender_email, password)
                    server.sendmail(sender_email, receiver_email, message)
                    server.quit()
                    break # Remove Break Statement to run after failer as well
                
                except (ConnectionError, TypeError, NameError, SyntaxError ) as error:
                        print(error)
time.sleep(3)
sock.close()