############## Stage 1
source "vmware-iso" "node-base" {
  guest_os_type     = var.guest-os-type
  version           = "19"
  iso_url           = var.iso-url
  iso_checksum      = var.iso-checksum
  ssh_username      = var.ssh-username
  ssh_password      = var.ssh-username
  ssh_agent_auth    = false
  ssh_wait_timeout  = "6000s"
  http_content      = {
    "/preseed.cfg" = templatefile("${var.guest-os-preseed-file}", { var = var })
  }
  disk_size         = "20480"
  disk_adapter_type = "sata"
  disk_type_id      = "0"
  headless          = var.headless
  vmx_data          = {
    "firmware"               = "efi"
    "vhv.enable"             = "TRUE"
    "ulm.disableMitigations" = "TRUE"
  }
  cpus              = 4 # number of vCpu
  cores             = 1 # number of cores per physical cpu (multi socket)
  memory            = 2048
  sound             = false
  usb               = false
  shutdown_command  = "echo '${var.ssh-username}' | sudo -S shutdown -P now"
  boot_wait         = "10s"
  boot_command      = [
    "<wait><wait><wait>c<wait><wait><wait>",
    "linux /install.amd/vmlinuz ",
    "auto=true ",
    "noapic ",
    "fb=false ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "hostname=${var.guest-os-hostname} ",
    "domain=${var.guest-os-domain} ",
    "interface=auto ",
    "vga=788 ",
    "noprompt ",
    "quiet -- <enter>",
    "initrd /install.amd/initrd.gz <enter>",
    "boot <enter>"
  ]
}

build {
  name = "stage1 - Setup base machine"
  source "source.vmware-iso.node-base" {
    vm_name          = local.nodes.base.name
    vmdk_name        = local.nodes.base.name
    output_directory = local.nodes.base.locations.stage1
    keep_registered  = false
    skip_export      = false
  }
}

############## Stage 2
source "vmware-vmx" "node-cluster-stage2" {
  ssh_username     = var.ssh-username
  ssh_password     = var.ssh-username
  ssh_agent_auth   = false
  ssh_wait_timeout = "6000s"
  shutdown_command = "echo '${var.ssh-username}' | sudo -S shutdown -P now"
  headless         = var.headless
  keep_registered  = false
  skip_export      = false
}

build {
  name = "stage2 - Prepare cluster images"
  source "vmware-vmx.node-cluster-stage2" {
    name             = "master"
    vm_name          = local.nodes.master.name
    vmdk_name        = local.nodes.master.name
    display_name     = local.nodes.master.name
    output_directory = local.nodes.master.locations.stage2
    source_path      = "${local.nodes.base.locations.stage1}/${local.nodes.base.name}.vmx"
  }
  source "vmware-vmx.node-cluster-stage2" {
    name             = "worker"
    vm_name          = local.nodes.worker.name
    vmdk_name        = local.nodes.worker.name
    display_name     = local.nodes.worker.name
    output_directory = local.nodes.worker.locations.stage2
    source_path      = "${local.nodes.base.locations.stage1}/${local.nodes.base.name}.vmx"
  }
  source "vmware-vmx.node-cluster-stage2" {
    name             = "deploy"
    vm_name          = local.nodes.deploy.name
    vmdk_name        = local.nodes.deploy.name
    display_name     = local.nodes.deploy.name
    output_directory = local.nodes.deploy.locations.stage2
    source_path      = "${local.nodes.base.locations.stage1}/${local.nodes.base.name}.vmx"
  }
  source "vmware-vmx.node-cluster-stage2" {
    name             = "proxy"
    vm_name          = local.nodes.proxy.name
    vmdk_name        = local.nodes.proxy.name
    display_name     = local.nodes.proxy.name
    output_directory = local.nodes.proxy.locations.stage2
    source_path      = "${local.nodes.base.locations.stage1}/${local.nodes.base.name}.vmx"
  }
  provisioner "file" {
    only        = ["vmware-vmx.master"]
    sources     = [
      "${local.config-folder}/k8s.common.setup.sh",
      "${local.config-folder}/k8s.runtime.setup.sh",
      "${local.config-folder}/k8s.node-master.setup.sh"
    ]
    destination = "${local.remote-config-folder}/"
  }
  provisioner "file" {
    only        = ["vmware-vmx.worker"]
    sources     = [
      "${local.config-folder}/k8s.common.setup.sh",
      "${local.config-folder}/k8s.runtime.setup.sh",
      "${local.config-folder}/k8s.node-worker.setup.sh"
    ]
    destination = "${local.remote-config-folder}/"
  }
  provisioner "file" {
    only        = ["vmware-vmx.deploy"]
    sources     = [
      "${local.config-folder}/k8s.common.setup.sh",
      "${local.config-folder}/k8s.node-deploy.setup.sh"
    ]
    destination = "${local.remote-config-folder}/"
  }
  provisioner "file" {
    only        = ["vmware-vmx.proxy"]
    sources     = [
      "${local.config-folder}/k8s.common.setup.sh",
      "${local.config-folder}/k8s.node-proxy.setup.sh"
    ]
    destination = "${local.remote-config-folder}/"
  }
  provisioner "shell" {
    only             = ["vmware-vmx.master"]
    environment_vars = [
      "KUBERNETES_OS_NAME=${var.kubernetes-os-name}",
      "KUBERNETES_VERSION=${var.kubernetes-version}",
    ]
    inline           = [
      "cd ${local.remote-config-folder}",
      "chmod u+x k8s.node-master.setup.sh",
      "./k8s.node-master.setup.sh",
      "rm -f *.setup.sh"
    ]
  }
  provisioner "shell" {
    only             = ["vmware-vmx.worker"]
    environment_vars = [
      "KUBERNETES_OS_NAME=${var.kubernetes-os-name}",
      "KUBERNETES_VERSION=${var.kubernetes-version}",
    ]
    inline           = [
      "cd ${local.remote-config-folder}",
      "chmod u+x k8s.node-worker.setup.sh",
      "./k8s.node-worker.setup.sh",
      "rm -f *.setup.sh"
    ]
  }
  provisioner "shell" {
    only             = ["vmware-vmx.deploy"]
    environment_vars = [
      "KUBERNETES_OS_NAME=${var.kubernetes-os-name}",
      "KUBERNETES_VERSION=${var.kubernetes-version}",
    ]
    inline           = [
      "cd ${local.remote-config-folder}",
      "chmod u+x k8s.node-deploy.setup.sh",
      "./k8s.node-deploy.setup.sh",
      "rm -f *.setup.sh"
    ]
  }
  provisioner "shell" {
    only             = ["vmware-vmx.proxy"]
    environment_vars = [
      "KUBERNETES_OS_NAME=${var.kubernetes-os-name}",
      "KUBERNETES_VERSION=${var.kubernetes-version}",
    ]
    inline           = [
      "cd ${local.remote-config-folder}",
      "chmod u+x k8s.node-proxy.setup.sh",
      "./k8s.node-proxy.setup.sh",
      "rm -f *.setup.sh"
    ]
  }
  provisioner "file" {
    sources     = [
      "${pathexpand(var.ssh-public-key)}",
      "${pathexpand(var.ssh-private-key)}"
    ]
    destination = "${local.remote-config-folder}/.ssh/"
  }
  provisioner "shell" {
    environment_vars = [
      "SSH_USERNAME=${var.ssh-username}",
      "SSH_PUBLIC_KEY=${basename(pathexpand(var.ssh-public-key))}",
      "SSH_PRIVATE_KEY=${basename(pathexpand(var.ssh-private-key))}"
    ]
    script           = "${local.config-folder}/k8s.finalize.setup.sh"
  }
  post-processor "vagrant" {
    only                = ["vmware-vmx.master"]
    keep_input_artifact = true
    output              = "${local.nodes.master.locations.stage3}/${local.nodes.master.name}.box"
  }
  post-processor "vagrant" {
    only                = ["vmware-vmx.worker"]
    keep_input_artifact = true
    output              = "${local.nodes.worker.locations.stage3}/${local.nodes.worker.name}.box"
  }
  post-processor "vagrant" {
    only                = ["vmware-vmx.deploy"]
    keep_input_artifact = true
    output              = "${local.nodes.deploy.locations.stage3}/${local.nodes.deploy.name}.box"
  }
  post-processor "vagrant" {
    only                = ["vmware-vmx.proxy"]
    keep_input_artifact = true
    output              = "${local.nodes.proxy.locations.stage3}/${local.nodes.proxy.name}.box"
  }
}

############## Stage 3
source "null" "the-void-stage3" {
  communicator = "none"
}

build {
  name = "stage3 - Add boxes to vagrant"
  source "null.the-void-stage3" {
    name = "master"
  }
  source "null.the-void-stage3" {
    name = "worker"
  }
  source "null.the-void-stage3" {
    name = "deploy"
  }
  source "null.the-void-stage3" {
    name = "proxy"
  }
  provisioner "shell-local" {
    only   = ["null.master"]
    inline = [
      "vagrant box add --force --name ${local.nodes.master.name} ${local.nodes.master.locations.stage3}/${local.nodes.master.name}.box"
    ]
  }
  provisioner "shell-local" {
    only   = ["null.worker"]
    inline = [
      "vagrant box add --force --name ${local.nodes.worker.name} ${local.nodes.worker.locations.stage3}/${local.nodes.worker.name}.box"
    ]
  }
  provisioner "shell-local" {
    only   = ["null.deploy"]
    inline = [
      "vagrant box add --force --name ${local.nodes.deploy.name} ${local.nodes.deploy.locations.stage3}/${local.nodes.deploy.name}.box"
    ]
  }
  provisioner "shell-local" {
    only   = ["null.proxy"]
    inline = [
      "vagrant box add --force --name ${local.nodes.proxy.name} ${local.nodes.proxy.locations.stage3}/${local.nodes.proxy.name}.box"
    ]
  }
}