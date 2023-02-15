# Using This We can get the Command Execution Output.
# #!/usr/bin/env python
# from netmiko import ConnectHandler

# cisco1 = {
#     "device_type": 'a10',
#     "host": "172.21.10.180",
#     "username": "admin",
#     "password": "a10",
#     # File name to save the 'session_log' to
#     "session_log": "output.txt"
# }

# # Show command that we execute
# command = "show ip"
# with ConnectHandler(**cisco1) as net_connect:
#     output = net_connect.send_command(command)


# Run this script

# from dotenv import load_dotenv
# import os
# from dotenv import dotenv_values

# export NAME=name
# load_dotenv()
# hello = os.getenv('UNAME')
# print(hello)

from netmiko import ConnectHandler

# Device one

a10_device0 = {
        "device_type": 'a10',
        "host": "172.28.254.21",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device0)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.254.21")
output = net_connect.send_command_timing("register")

print("Output Device1: " + output)
print("\n")

# Device two

a10_device1 = {
        "device_type": 'a10',
        "host": "172.28.254.22",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device1)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.254.22")
output1 = net_connect.send_command_timing("register")

print("Output Device2: " + output1)
print("\n")

# Device three

a10_device2 = {
        "device_type": 'a10',
        "host": "172.28.254.23",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device2)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.254.23")
output = net_connect.send_command_timing("register")

print("Output Device3: " + output)
print("\n")


# Device four

a10_device3 = {
        "device_type": 'a10',
        "host": "172.28.253.21",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device3)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.253.21")
output = net_connect.send_command_timing("register")

print("Output Device3: " + output)
print("\n")


# Device five

a10_device4 = {
        "device_type": 'a10',
        "host": "172.28.253.22",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device4)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.253.22")
output = net_connect.send_command_timing("register")

print("Output Device4: " + output)
print("\n")


# Device six

a10_device5 = {
        "device_type": 'a10',
        "host": "172.28.253.23",
        "username": "admin",
        "password": "a10",
}

net_connect = ConnectHandler(**a10_device5)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("exit")
net_connect.send_command_timing("no harmony-controller profile")
net_connect.send_command_timing("y")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("host 172.21.10.157 use-mgmt-port port 443")
net_connect.send_command_timing("provider root")
net_connect.send_command_timing("user-name super-admin")
net_connect.send_command_timing("password P@ssw0rd@123")
net_connect.send_command_timing("thunder-mgmt-ip 172.28.253.23")
output = net_connect.send_command_timing("register")

print("Output Device5: " + output)
print("\n")