# Azure Virtual Desktop Solution

[**Home**](../readme.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Post Deployment**](./post.md) | [**Troubleshooting**](./troubleshooting.md)

## Troubleshooting

If you need to redeploy this solution b/c of an error or other reason, be sure the virtual machines are turned on.  If your host pool is "pooled", I would recommended disabling your logic app to ensure the scaling solution doesn't turn off any of your VMs during the deployment.  If the VMs are off, the deployment will fail since the extensions cannot be validated / updated.
