if __name__=="__main__":
    in_data=''
    with open('/etc/sudoers','r') as file_in:
        in_data=file_in.read()
    new_data=in_data.replace('%root ALL=(ALL:ALL) ALL','%root ALL=(ALL:ALL) NOPASSWD: ALL')
    new_data=new_data.replace('# %sudo ALL=(ALL:ALL) ALL','%sudo ALL=(ALL:ALL) NOPASSWD: ALL')
    new_data=new_data.replace('# %wheel ALL=(ALL:ALL) NOPASSWD: ALL','%wheel ALL=(ALL:ALL) NOPASSWD: ALL')
    with open('/etc/sudoers','w') as file_out:
        file_out.write(new_data)