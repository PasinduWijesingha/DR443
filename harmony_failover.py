import socket
import time
import smtplib
import os
from netmiko import ConnectHandler

ip_address = "172.21.10.156" 

while(True):

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('172.21.10.156',443))
    
    if result == 0:
        print ("Open Port")
        time.sleep(600)

    else:
        print ("Close Port")   
        time.sleep(600)

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('172.21.10.156',443)) 

        if result == 0:
            print ("Open Port")
            time.sleep(300)
            continue

        else:

            print ("Close Port")   
            time.sleep(300)

            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('172.21.10.156',443)) 

            if result == 0:
                print ("Open Port")
                time.sleep(150)
                continue

            else:

                print ("Close Port")   
                time.sleep(150)

                # --------------------- After sussesful disaster this part will run -------------------------

                try : 

                    HarmonyController  = {
                            "device_type": 'a10',
                            "host": "172.21.10.156",
                            "username": "root",
                            "password": "P@ssw0rd@123",
                        }

                    net_connect = ConnectHandler(**HarmonyController )
                    output = net_connect.send_command_timing("systemctl stop crond.service")

                    print(output)

                except (ConnectionError, TypeError, NameError, SyntaxError ) as error:
                        #net_connect.exit()
                        print(error)
                
                #COMMAND NEED TO RUN

                cmd1 = './harmony_restore.sh --metrics=no' 

                cmd2 = 'python3.7 device_registration_from_hq_to_dr.py'  

		    cmd3 = 'python3.7 rollback.py'
                
		    os.system(cmd1)

                os.system(cmd2)

		    os.system(cmd3)

                #try: 

                    #SEND YOUR MAIL
                    #sender_email = "Sender Mail" 
                    #receiver_email = "Receiver Mail" 
                    #password = "Enter Password" 
                    #message = "Hello World !!!"

                    #server = smtplib.SMTP("smtp.office365.com", 587) 
                    #server.starttls()
                    #server.login(sender_email, password)
                    #server.sendmail(sender_email, receiver_email, message)
                    #server.quit()
                    #break 
                
                #except (ConnectionError, TypeError, NameError, SyntaxError ) as error:

                        print(error)


time.sleep(3)
sock.close()