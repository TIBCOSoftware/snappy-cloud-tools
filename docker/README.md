## Setting up Cluster with SnappyData Docker Image
###Prerequisites

* This guide assumes that Docker have been installed and configured. Refer to [Docker documentation](http://docs.docker.com/installation) for more information.
* Ensure that Docker containers have access to at least 2GB of RAM on your machine. 
* If you are running Docker on a Mac or PC you may need to modify the RAM used by the virtual machine which is
running the Docker daemon. For more information, refer to the Docker documentation.

**Verify that your installation is working correctly**

```
$ docker run hello-world
```

**Start a basic cluster with one data node, one lead and one locator**

```
$ docker run -itd --net=host --name snappydata snappydatainc/snappydata start all
```
**Check the Docker process**

```
$ docker ps -a
```
<Note>Note: Wait for a few seconds before running the next command.</Note>

**Check the Docker logs**<br>
The following command displays the logs of container process. The query results display “Distributed system now has 3 members”.


```
$ docker logs snappydata
starting sshd service
Starting sshd:
 [ OK ]
 Starting SnappyData Locator using peer discovery on: localhost[10334]
 Starting DRDA server for SnappyData at address localhost/127.0.0.1[1527]
 Logs generated in /opt/snappydata/work/localhost-locator-1/snappylocator.log
 SnappyData Locator pid: 110 status: running
 Starting SnappyData Server using locators for peer discovery: localhost:10334
 Starting DRDA server for SnappyData at address localhost/127.0.0.1[1527]
 Logs generated in /opt/snappydata/work/localhost-server-1/snappyserver.log
 SnappyData Server pid: 266 status: running
 Distributed system now has 2 members.
 Other members: localhost(110:locator)<v0>:63369
 Starting SnappyData Leader using locators for peer discovery: localhost:10334
 Logs generated in /opt/snappydata/work/localhost-lead-1/snappyleader.log
 SnappyData Leader pid: 440 status: running
 Distributed system now has 3 members.
 Other members: 192.168.1.130(266:datastore)<v1>:47290, localhost(110:locator)<v0>:63369

 ```

 **Connect SnappyData with the Command Line Client**
 ```
 $ docker exec -it snappydata ./bin/snappy-shell
 ```
 **Connect Client on port “1527”**

 ```
 $ snappy> connect client 'localhost:1527';
 ```

 **View Connections**

 ```
 snappy> show connections;
 CONNECTION0* -
  jdbc:gemfirexd://localhost[1528]/
  * = current connection

  ```
  **Check Member Status**

  ```
  snappy> show members;
  ```

  **Stop the Cluster**

  ```
  $ docker exec -it snappydata ./sbin/snappy-stop-all.sh
  The SnappyData Leader has stopped.
  The SnappyData Server has stopped.
  The SnappyData Locator has stopped.
  ```

  **Stop SnappyData Container**
  ```
  $ docker stop snappydata
  ```
