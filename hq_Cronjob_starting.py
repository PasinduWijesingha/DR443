from netmiko import ConnectHandler

a10_HQ_Harmony = {
        "device_type": 'a10',
        "host": "172.28.254.21",
        "username": "admin",
        "password": "a10",
}

net_connect.send_command_timing("systemctl restart crond.service")