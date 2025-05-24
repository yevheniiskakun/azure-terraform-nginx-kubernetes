resource "random_pet" "name" {

}

resource "azurerm_resource_group" "custom-site-rg" {
  name     = "${random_pet.name.id}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${random_pet.name.id}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.custom-site-rg.name
  dns_prefix          = "${random_pet.name.id}-dns"

  # Modifing default name "MC_<resource_group>_<cluster_name>_<location>" of additional RG created automatically to manage unerlying infrastucture 
  node_resource_group = "${random_pet.name.id}-aks-nodes" 

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Demo"
  }
}

# Set up kubernetes provider
provider "kubernetes" {
  host = azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_deployment" "custom-site" {
  metadata {
    name = "${random_pet.name.id}-custom-site-deployment"
    labels = {
      app = "custom-site"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "custom-site"
      }
    }

    template {
      metadata {
        labels = {
          app = "custom-site"
        }
      }

      spec {
        container {
          name  = "custom-site-container"
          image = "openheineken/my-custom-site:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "custom-site" {
  metadata {
    name = kubernetes_deployment.custom-site.name
  }

  spec {
    selector = {
      app = kubernetes_deployment.custom-site.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

