# Workaround for SelfSigned Cert an force TLS 1.2
add-type @”
	using System.Net;
	using System.Security.Cryptography.X509Certificates;
	public class TrustAllCertsPolicy : ICertificatePolicy {
		public bool CheckValidationResult(
		ServicePoint srvPoint, X509Certificate certificate,
		WebRequest request, int certificateProblem) {
			return true;
		}
	}
“@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# use 'library/' prefix for 'official' images like postgres 
$image = "atlassian/jira-software" 
$tag = "8.13.2" 

$imageuri = "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${image}:pull" 
$taguri = "https://registry-1.docker.io/v2/${image}/manifests/${tag}"
$bloburi = "https://registry-1.docker.io/v2/${image}/blobs/" 

# generating folder to save image files 
$path = "$image$tag" -replace '[\\/":*?<>|]'
if (!(test-path $path)) { 
	New-Item -ItemType Directory -Force -Path $path 
} 

# token request 
$token = Invoke-WebRequest -Uri $imageuri | ConvertFrom-Json | Select -expand token 

# getting image manifest 
$headers = @{} 
$headers.add("Authorization", "Bearer $token") 
# this header is needed to get manifest in correct format: https://docs.docker.com/registry/spec/manifest-v2-2/ 
$headers.add("Accept", "application/vnd.docker.distribution.manifest.v2+json") 
$manifest = Invoke-Webrequest -Headers $headers -Method GET -Uri $taguri | ConvertFrom-Json 

# downloading config json 
$configSha = $manifest | Select -expand config | Select -expand digest 
$config = ".\$path\config.json" 
Invoke-Webrequest -Headers @{Authorization="Bearer $token"} -Method GET -Uri $bloburi$configSha -OutFile $config 

# generating manifest.json 
$manifestJson = @{} 
$manifestJson.add("Config", "config.json") 
$manifestJson.add("RepoTags",@("${image}:${tag}")) 

# downloading layers 
$layers = $manifest | Select -expand layers | Select -expand digest 
$blobtmp = ".\$path\blobtmp" 

#downloading blobs 
$layersJson = @() 
foreach ($blobelement in $layers) { 
	# making so name doesnt start with 'sha256:' 
	$fileName = "$blobelement.gz" -replace 'sha256:' 
	$newfile = ".\$path\$fileName" 
	$layersJson += @($fileName) 

	# token expired after 5 minutes, so requesting new one for every blob just in case 
	$token = Invoke-WebRequest -Uri $imageuri | ConvertFrom-Json | Select -expand token 
	
	Invoke-Webrequest -Headers @{Authorization="Bearer $token"} -Method GET -Uri $bloburi$blobelement -OutFile $blobtmp 
	
	Copy-Item $blobtmp $newfile -Force -Recurse 
} 

# removing temporary blob 
Remove-Item $blobtmp 

# saving manifest.json 
$manifestJson.add("Layers", $layersJson) 
ConvertTo-Json -Depth 5 -InputObject @($manifestJson) | Out-File -Encoding ascii ".\$path\manifest.json" 

# postprocessing
echo "copy generated folder to your docker machine" 
echo "tar -cvf imagename.tar *" 
echo "docker load < imagename.tar"