c.NotebookApp.open_browser = False
c.NotebookApp.ip='0.0.0.0' #'*'
c.NotebookApp.port = 8192 # If you change the port here, make sure you update it in the jupyter_installer.sh file as well
c.NotebookApp.password = u'sha1:45f7d7ac038c:c36b98f22eac5921c435095af65a9a00b0e1eeb9'
c.Authenticator.admin_users = {'jupyter'}
c.LocalAuthenticator.create_system_users = True
