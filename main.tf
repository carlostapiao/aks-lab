provider "azurerm" {
  features {}
  subscription_id = "e690edad-0257-4dec-b4c9-08e163433edb"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-k8s-lab"
  location = "centralus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_container_registry" "acr" {
  name                = "carlos69lamejor"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-lab"

  private_cluster_enabled = true

  default_node_pool {
    name       = "nodepool1"
    node_count = 1
    vm_size    = "Standard_B2ps_v2"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}