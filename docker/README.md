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
  jdbc:gemfirexd://localhost[1527]/
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




###Using Multiple Containers with docker-compose

  Install docker-compose from [Docker documentation](https://docs.docker.com/compose/install/) 

  Verify installation by checking version of docker-compose

  ```
  $ docker-compose -v
  docker-compose version 1.8.1, build 878cff1
  ```

  ```
  $ docker-compose up -d
  Creating network "docker_default" with the default driver
  Creating locator1_1
  Creating server1_1
  Creating snappy-lead1_1
  ```

  ```
  $ docker-compose logs
  Attaching to snappy-lead1_1, server1_1, locator1_1
  server1_1       | Starting SnappyData Server using locators for peer discovery: locator1:10334
  server1_1       | Starting DRDA server for SnappyData at address server1/172.18.0.3[1528]
  snappy-lead1_1  | Starting SnappyData Leader using locators for peer discovery: locator1:10334
  server1_1       | Logs generated in /opt/snappydata/work/localhost-server-1/snappyserver.log
  snappy-lead1_1  | Logs generated in /opt/snappydata/work/localhost-lead-1/snappyleader.log
  server1_1       | SnappyData Server pid: 83 status: running
  snappy-lead1_1  | SnappyData Leader pid: 83 status: running
  server1_1       |   Distributed system now has 2 members.
  snappy-lead1_1  |   Distributed system now has 3 members.
  snappy-lead1_1  |   Other members: docker_server1_1(83:datastore)<v1>:53707, locator1(87:locator)<v0>:44102
  server1_1       |   Other members: locator1(87:locator)<v0>:44102
  locator1_1      | Starting SnappyData Locator using peer discovery on: locator1[10334]
  locator1_1      | Starting DRDA server for SnappyData at address locator1/172.18.0.2[1527]
  locator1_1      | Logs generated in /opt/snappydata/work/localhost-locator-1/snappylocator.log
  locator1_1      | SnappyData Locator pid: 87 status: running
  ```

  **Connect SnappyData with the Command Line Client on server1_1**

  ```
  $ docker exec -it server1_1 ./bin/snappy-shell
  ```

  ```
  $ snappy> connect client 'localhost:1527';
  ```

  **View Connections**

  ```
  snappy> show connections;
  CONNECTION0* -
   jdbc:gemfirexd://localhost[1527]/
   * = current connection
   ```

   **Stopping docker-compose**

   To stop and remove containers from docker-enginet

   ```
   $ docker-compose down
   Stopping snappy-lead1_1 ... done
   Stopping server1_1 ... done
   Stopping locator1_1 ... done
   Removing snappy-lead1_1 ... done
   Removing server1_1 ... done
   Removing locator1_1 ... done
   Removing network docker_default
   ```

