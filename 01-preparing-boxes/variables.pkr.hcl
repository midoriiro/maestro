variable "guest-os-preseed-file" {
  type = string
}

variable "guest-os-name" {
  type = string
}

variable "guest-os-type" {
  type = string
}

variable "guest-os-language" {
  type = string
}

variable "guest-os-country" {
  type = string
}

variable "guest-os-locale" {
  type = string
}

variable "guest-os-keyboard-layout" {
  type = string
}

variable "guest-os-domain" {
  type = string
}

variable "guest-os-hostname" {
  type = string
}

variable "guest-os-mirror-hostname" {
  type = string
}

variable "guest-os-mirror-path" {
  type = string
}

variable "guest-os-timezone" {
  type = string
}

variable "kubernetes-os-name" {
  type = string
}

variable "kubernetes-version" {
  type = string
}

variable "iso-url" {
  type = string
}

variable "iso-checksum" {
  type = string
}

variable "root-folder" {
  type    = string
  default = "../.boxes"
}

variable "headless" {
  type = bool
}

variable "ssh-username" {
  type = string
}

variable "ssh-public-key" {
  type = string
}

variable "ssh-private-key" {
  type = string
}

local "config-folder" {
  expression = "${abspath(path.root)}/configs"
}

local "remote-config-folder" {
  expression = "/home/${var.ssh-username}"
}

local "boxes-version" {
  expression = file("../VERSION")
}

locals {
  stage-folders = {
    stage1 = "${pathexpand(var.root-folder)}/${local.boxes-version}/stage-1"
    stage2 = "${pathexpand(var.root-folder)}/${local.boxes-version}/stage-2"
    stage3 = "${pathexpand(var.root-folder)}/${local.boxes-version}/stage-3"
    stage4 = "${pathexpand(var.root-folder)}/${local.boxes-version}/stage-4"
  }
}

locals {
  nodes = {
    base = {
      name      = "k8s.node-base.${var.guest-os-name}"
      locations = {
        stage1 = "${local.stage-folders.stage1}/base"
        stage2 = "${local.stage-folders.stage2}/base"
        stage3 = "${local.stage-folders.stage3}/base"
        stage4 = "${local.stage-folders.stage4}/base"
      }
    }

    master = {
      name      = "k8s.node-master.${var.guest-os-name}"
      locations = {
        stage1 = "${local.stage-folders.stage1}/master"
        stage2 = "${local.stage-folders.stage2}/master"
        stage3 = "${local.stage-folders.stage3}/master"
        stage4 = "${local.stage-folders.stage4}/master"
      }
    }

    worker = {
      name      = "k8s.node-worker.${var.guest-os-name}"
      locations = {
        stage1 = "${local.stage-folders.stage1}/worker"
        stage2 = "${local.stage-folders.stage2}/worker"
        stage3 = "${local.stage-folders.stage3}/worker"
        stage4 = "${local.stage-folders.stage4}/worker"
      }
    }

    deploy = {
      name      = "k8s.node-deploy.${var.guest-os-name}"
      locations = {
        stage1 = "${local.stage-folders.stage1}/deploy"
        stage2 = "${local.stage-folders.stage2}/deploy"
        stage3 = "${local.stage-folders.stage3}/deploy"
        stage4 = "${local.stage-folders.stage4}/deploy"
      }
    }

    proxy = {
      name      = "k8s.node-proxy.${var.guest-os-name}"
      locations = {
        stage1 = "${local.stage-folders.stage1}/proxy"
        stage2 = "${local.stage-folders.stage2}/proxy"
        stage3 = "${local.stage-folders.stage3}/proxy"
        stage4 = "${local.stage-folders.stage4}/proxy"
      }
    }
  }
}