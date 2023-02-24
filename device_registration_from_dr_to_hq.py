from netmiko import ConnectHandler

# Device one

a10_device1 = {

    "device_type": 'a10',
    "host": "172.21.10.180",
    "username": "admin",
    "password": "a10",
}

net_connect = ConnectHandler(**a10_device1)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("host 172.21.10.156 use-mgmt-port port 443")
output = net_connect.send_command_timing("register")

print("Output Device1: " + output)
print("\n")

# Device two

a10_device2 = {

    "device_type": 'a10',
    "host": "172.21.10.181",
    "username": "admin",
    "password": "a10",
}

net_connect = ConnectHandler(**a10_device2)
net_connect.enable()
net_connect.send_command_timing("configure terminal")
net_connect.send_command_timing("harmony-controller profile")
net_connect.send_command_timing("deregister")
net_connect.send_command_timing("host 172.21.10.156 use-mgmt-port port 443")
output1 = net_connect.send_command_timing("register")

print("Output Device2: " + output1)
print("\n")


