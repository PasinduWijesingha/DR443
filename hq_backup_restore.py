from netmiko import ConnectHandler

a10_HQ_Harmony = {

        "device_type": 'hc',
        "host": "172.21.10.156",
        "username": "root",
        "password": "P@ssw0rd@123",
}

net_connect.send_command_timing("./harmony_restore.sh --metrics=no")