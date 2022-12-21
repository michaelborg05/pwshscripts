# this is the batch file to build and run the docker image

docker build --no-cache -t linuxpwrsh .
docker rm nfts -f
docker run -d -v "$(pwd):/pwshscripts/config" --name nfts linuxpwrsh pwsh MonitorNFTFloor.ps1
