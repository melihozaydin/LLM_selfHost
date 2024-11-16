# My personal LLM services
- Ollama

- OpenWebUI
	- Searxng (for web search capability)
### TODO
- Web Searxng
	- Update deploy script with Searxng
		- Searxng Port is 8080 (Same as OpenWebUI)
		- Also defined in searxng/config.yml
		- Do we need Redis?

- Document RAG 
	- https://github.com/Cinnamon/kotaemon
	

- TTS - STT
	- openedai (TTS)
	- whisper (STT)
	
- Image generation
	- ComfyUI

- workflow automation
	- N8n
		https://docs.n8n.io/hosting/installation/docker/
	

# OllamaWebUI Hosts Error
	# WIP
	"""
	Error: failed to create new hosts file: 
	unable to replace "host-gateway" of host entry "host.docker.internal:host-gateway": 
	host containers internal IP address is empty
	"""
	- Links:
		* https://github.com/containers/podman/issues/21681
		

     enable host network on podman machine setup

# Installation
"""
cd ollama-docker

mkdir ollama/webui
mkdir ollama/ollama

podman compose --file docker-compose-ollama-gpu.yaml up --detach

# Important Note : 

Podman compose does not work properly with GPU devices even tough 
"podman run --device nvidia.com/gpu=all " works with gpus just fine.

So setting up the containers by script is needed if using podman instead of docker.

---

**** NVIDIA CDI Installation

	"""
	- you need nvidia-container-toolkit in the podman machine ssh
		- https://github.com/containers/podman/issues/19005#issuecomment-1752098959
		-- Podman NVIDIA CDI installation
		- Source:
			https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-yum-or-dnf
			https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html#procedure
	"""

	- Connect to podman wsl machine
		""" 
		podman machine ssh
		"""

	- Generate the CDI specification file:

		"""
		sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
		"""

	- The sample command uses sudo to ensure that the file at /etc/cdi/nvidia.yaml is created. You can omit the --output argument to print the generated specification to STDOUT.

		Example Output
		"""
		INFO[0000] Auto-detected mode as "nvml"
		INFO[0000] Selecting /dev/nvidia0 as /dev/nvidia0
		INFO[0000] Selecting /dev/dri/card1 as /dev/dri/card1
		INFO[0000] Selecting /dev/dri/renderD128 as /dev/dri/renderD128
		INFO[0000] Using driver version xxx.xxx.xx
		...
		"""
	- (Optional) Check the names of the generated devices:
		"""
		nvidia-ctk cdi list
		"""
	- The following example output is for a machine with a single GPU that does not support MIG.
		"""
		INFO[0000] Found 9 CDI devices
		nvidia.com/gpu=all
		nvidia.com/gpu=0
		"""


	curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
	sudo yum install -y nvidia-container-toolkit
	"""
	
	
	"""
	** Important

	You must generate a new CDI specification after any of the following changes:

		You change the device or CUDA driver configuration.

		You use a location such as /var/run/cdi that is cleared on boot.

	A configuration change can occur when MIG devices are created or removed, or when the driver is upgraded.
	"""
	
	- Test GPU access
		"""
		podman run --rm --device nvidia.com/gpu=0 ubuntu nvidia-smi -L
		"""
---


### NOTE: ACCESS from LAN devices

	(https://github.com/containers/podman/issues/17030)
	WSL traffic is isolated to a separate network interface from Windows applications (this is the vWSL interface).
	- PORT FORWARDİNG ISSUE ON LAN : https://github.com/containers/podman/issues/17030
	If you need the port to be remotely accessible to other systems on the lan you need to add an ip forward 
	- see bottom section of https://learn.microsoft.com/en-us/windows/wsl/networking
  	-------------
	* STEP1: Find podman-WSL IP
	"""Bash(WSL)
	ip route show | grep -i default | awk '{ print $3}'
	"""
	or 
	""" Powershell(Host)
	podman machine ssh "ip route show | grep -i default | awk '{ print $3}'"
	"""
	* STEP2: PortForward WSL ports to Host
	""" Powershell (HOST)
	netsh interface portproxy add v4tov4 listenport=8087 listenaddress=0.0.0.0 connectport=8080 connectaddress=192.168.127.1
	netsh interface portproxy show all
	"""
	* STEP3: Add Firewall inbound exceptions
	-----------------
	!!! Warning: WSL IP cahanges on each bootup
	OR

	-----------------
	Src: (https://github.com/microsoft/WSL/issues/4150#issuecomment-504209723)
	run "wslbridge.ps1" on login with admin privilages
	
	-----------------


### Websearch
use internal port for searxng port:
http://searxng:8080/search?q=<query>

hostname is auto resolved as the container name from the same podman network
you can also directly write ip from : podman inspect searxng instead like
http://10.89.1.29:8080/search?q=<query>

** (ollama-webui) Something went wrong :/ [Errno -2] Name or service not known 
- setting Search Result Count to 2 and  concurrent requests to 5 fixed it 



### Tool use
# add websearch as a tool so llm rephrases according to context
https://docs.openwebui.com/tutorial/tools

### Image generation
- setupConnect comfyui as docker that connects to Ollama
https://github.com/alisson-anjos/ComfyUI-Ollama-Describer
https://www.reddit.com/r/comfyui/comments/1dc80al/installing_comfyui_in_a_docker_container/