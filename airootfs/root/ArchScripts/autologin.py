if __name__=="__main__":
    in_data=""
    with open('/etc/pam.d/gdm-password','r') as file:
        in_data=file.read()
    in_data=in_data.replace("#%PAM-1.0","#%PAM-1.0 \n auth sufficient pam_succeed_if.so user ingroup nopasswdlogin")
    with open('/etc/pam.d/gdm-password','w') as file:
        file.write(in_data)