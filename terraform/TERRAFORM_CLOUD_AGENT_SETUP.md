# Terraform Cloud Agent Setup

## Why Use an Agent?

You're right! **Terraform Cloud Agents** are perfect for your homelab:
- ✅ Runs on your local machine (can reach 10.0.0.9)
- ✅ Pulls secrets from Terraform Cloud (no local storage)
- ✅ Reports back to Terraform Cloud (state stored remotely)
- ✅ Secure - secrets never leave Terraform Cloud UI

## Step 1: Create Agent Pool

1. Go to your Terraform Cloud organization settings:
   **https://app.terraform.io/app/homelabStoaties/settings/agents**

2. Click **"Create an agent pool"**
   - Name: `homelab-agents`
   - Click **Create agent pool**

3. Click **"Create agent token"**
   - Description: `homelab-windows-agent`
   - **COPY THE TOKEN** - you'll only see it once!

## Step 2: Install Agent on Your Computer

### Option A: Docker (Recommended)

```powershell
# Save the token
$env:TFC_AGENT_TOKEN = "your-agent-token-here"

# Run the agent
docker run -d `
  --name terraform-cloud-agent `
  --restart unless-stopped `
  -e TFC_AGENT_TOKEN=$env:TFC_AGENT_TOKEN `
  -e TFC_AGENT_NAME="homelab-windows-agent" `
  hashicorp/tfc-agent:latest
```

### Option B: Native Windows Binary

1. Download the agent:
   ```powershell
   # Download latest version
   Invoke-WebRequest -Uri "https://releases.hashicorp.com/tfc-agent/1.15.0/tfc-agent_1.15.0_windows_amd64.zip" -OutFile "tfc-agent.zip"
   
   # Extract
   Expand-Archive -Path tfc-agent.zip -DestinationPath C:\tfc-agent
   ```

2. Create configuration file `C:\tfc-agent\config.hcl`:
   ```hcl
   token = "your-agent-token-here"
   name  = "homelab-windows-agent"
   ```

3. Run the agent:
   ```powershell
   cd C:\tfc-agent
   .\tfc-agent.exe run -config config.hcl
   ```

4. **(Optional)** Install as Windows Service:
   ```powershell
   # Using NSSM (Non-Sucking Service Manager)
   choco install nssm
   nssm install TerraformCloudAgent "C:\tfc-agent\tfc-agent.exe" "run -config C:\tfc-agent\config.hcl"
   nssm start TerraformCloudAgent
   ```

## Step 3: Configure Workspace to Use Agent

1. Go to workspace settings:
   **https://app.terraform.io/app/homelabStoaties/homelab-proxmox/settings/general**

2. **Execution Mode** section:
   - Change from "Local" to **"Agent"**
   - **Agent Pool**: Select `homelab-agents`
   - Click **Save settings**

## Step 4: Set Variables in Terraform Cloud

**https://app.terraform.io/app/homelabStoaties/homelab-proxmox/settings/variables**

Add these variables:

### Variable 1: proxmox_endpoint
- Key: `proxmox_endpoint`
- Value: `https://10.0.0.9:8006/api2/json`
- Category: **Terraform variable**
- Sensitive: No

### Variable 2: proxmox_api_token
- Key: `proxmox_api_token`
- Value: `terraform-prov@pve!terraform-cloud=YOUR_SECRET_HERE`
- Category: **Terraform variable**
- Sensitive: ✅ **YES**

## Step 5: Run Terraform

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform plan
```

Now:
- Execution happens on **your agent** (can reach Proxmox)
- Variables pulled from **Terraform Cloud** (secure)
- State stored in **Terraform Cloud** (remote)
- No secrets on local disk! ✅

## Verify Agent is Running

Check the agent pool page:
**https://app.terraform.io/app/homelabStoaties/settings/agents**

You should see your agent with status **"Idle"** or **"Busy"**

## Troubleshooting

### Agent not appearing in pool
- Check token is correct
- Verify agent process is running: `docker ps` or Task Manager
- Check logs: `docker logs terraform-cloud-agent`

### "No agents available"
- Make sure agent is running and showing "Idle"
- Verify workspace is configured to use the correct agent pool
- Check agent has network access to internet (to communicate with Terraform Cloud)

### "Network unreachable" still happening
- Agent must run on same network as Proxmox (or have route to 10.0.0.9)
- Test from agent machine: `curl -k https://10.0.0.9:8006`

## Agent Requirements

- Network access to Terraform Cloud (outbound HTTPS)
- Network access to Proxmox (10.0.0.9:8006)
- ~512MB RAM per agent
- Windows/Linux/macOS supported

## Next Steps

1. Create agent pool & token in Terraform Cloud
2. Run agent on your computer (Docker or native)
3. Configure workspace to use agent execution mode
4. Set variables in Terraform Cloud
5. Run `terraform plan` - secrets stay in cloud! 🔐
