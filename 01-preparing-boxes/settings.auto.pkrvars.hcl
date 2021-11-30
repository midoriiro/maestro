# root folder is used for running virtual machine and create vagrant boxes (default = <project-root>/.boxes).
# - if your git project copy is not localised on an SSD and you would run your cluster on a SSD
# - Just uncomment `root-folder` variable line definition and define your custom location
root-folder    = "~/.maestro"
headless       = true
ssh-username   = "kuber"
ssh-public-key = "~/.ssh/kuber/id_ed25519.pub"