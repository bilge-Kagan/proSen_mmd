# ProSen MMD
***Caution:*** This project is **not completed** yet. For more information, read "*Why Not Runnable Now?*"
part at below.

### Definition
ProSen MMD (*Measure Management and Database*) is project which intends to measure
temperature and humidity at various environments, then store these measurements in database, and
finally process/manage the data.

It is really cheap solution to get control and process something's temperature and humidity data.
The thing may be any silo,any tank, any store etc.


## System Topology
Prosen MMD is occurred by these elements:
* Server
* Database server
* Single-board computer(s)
* Sensors which are convenient for our single-board computers

Lets look at the chart at below and analyze the working principle:

![proSen_mmd_flowchart](https://github.com/bilge-Kagan/proSen_mmd/blob/master/charts/proSen_mmd.png "proSen_mmd_flowchart" )

As you see, the workflow is like that:
1. Temperature and humidity are measured by sensors (*<sensor1@slave1>, <sensor0@slave3> etc.*) for every *"defined"
interval time* seconds
2. The measurements are initially stored by slaves (*'slave1', 'slave3' etc.*)
3. According to *"defined" interval time* of measure, the *'master'* single-boards
computer is request to slaves (*'slave1', or itself 'slave0' etc.*) for the measurement data
4. Slaves (*'slave0', 'slave2' etc.*) send to master the data they hold then remove them from
their local storage
5. The data acquired by *'master'*, stored in local storage of *'master'* until the
*'sever'* request for them
6. Again according to *"defined" interval time*, the *'server'* requests to the *'master'*
single-board computer for the data
7. Data stored in local storage of *'master'* is removed and
it acquired by the *'server'*, then the data is saved to database
8. So, the system replay this loop until we stop it; or crash (just a probability, of course)..

The **"defined" interval time** is interval time for measurement. For instance, if we define it 10 seconds
before start the system, then sensors measure temperature and humidity for every 10 seconds.
Of course, minimum level of this value is related with *"sensor chip"* specifications.

The single-board computers i used is *Raspberry Pi*. But you can what you want. For instance:
*Orange Pi, Nano Pi, LattePanda* etc.  

## Database Analyze
We have huge database problem again (again, because of [drRey](https://github.com/bilge-Kagan/drRey)). Because just think count of measures
in one month if we have 6 sensors and define interval time as 10 seconds:`(30 * 24 * 60 * 60) / 10`
measurements for every sensor. Then `259_200 * 6`, totally: `1_555_200` records. Wow, just in one month.

So after we proved the database is huge, lets explain how we handle this problem.

Firstly, look at the database diagram at below:

![database_diagram](https://github.com/bilge-Kagan/proSen_mmd/blob/master/charts/proSenMMD_database_diagram.png "database_diagram")

There is six tables as you see. You can understand what store they. By the way, there is used MySQL
as RDMS. So SQL scripts in project have MySQL syntax.

* We need to process the data and then we must achieve results simply and fast of course. Except of abnormal
situations, nobody wants to reach measurements one by one. So, there is *"statistics"* table. All data
we need stored there, and can be reached in a short time. Because there is a few rows, as number of sensors.

* Last measurements are stored in *"sensors"* table. If we want to watch in real time, again it is so
quickly. Also the server does not slog on, despite of real time watch.

* *"bounds"* table stores maximum limit values of temperature and humidity. If our measures exceed this
values, records are saved in "*overflows*" table. Also, they are saved "*measurements*" table. With
this way, we can check that our environment is in safe level of temperature and humidity.

In `/db/Procedure(s)` and `/db/Trigger(s)` locations, there are some '*.sql*' scripts. We dropped on database all
data checks, data comparisons, calculation operations (*mean humidity, count of measurements etc.*).
It processes them as soon as the new data came and saves results to appropriate tables. So, when you
need them, you won't wait. Also, the web server will not be bussy with this operations.

### How Do Concurrency?
As you know, there must be concurrency. Because of: to request for new data,
to store data belong for last hour in physically file out of SQL database (yes, the server can do it; just an detail),
to handle clients requests and commands (*"start/stop system", "get/delete data" etc.*), to check bound file is there
(another detail, the limit values of temperature and humidity are received from file) and so on; they must be
concurrent.

We did it via *"Thread class"*, not used any additional *gem* (some Rails projects are only made by gems, really).
Believe me, with this way the concurrency becomes so stable, as stable as Ruby.

You can check *thread classes* we made in `/lib/threadClass(s)/` directory. These thread variables are defined
in `/config/initializers/constants_and_globals.rb` as *global* variables. Because we need only one
thread for each other. When the server is started, these threads are created.

In same directory, you can see other scripts to run the system. They contain *methods*, so much *methods*.
I explained which method do what as i could in scripts. If you want to ask something, you can ask with mail
in "**Contact**" (at below) part.

## Why Not Runnable Now?
Nice question, because of there is no stable script for *single-board computer* and
no GUI in project (it is in design stage).

As GUI, i want to use standard browser like a web page. With this way, it can be reachable in any
PC, mobile, tablet etc. But i need more *javascript* skill to do my mind.

In the future, API can be developed of course.

Other problem, the stable script for *single-board computer*. I've script for this job
written in *Python*. But not stable, also i didn't write it myself, my mate did. I decided to write it
again via *Ruby*. Hopefully, very soon. Difficulty is that sensors you used may not have appropriate
library for *Ruby*. So you can not read measurements from sensor. To solve this, i can write
*C program* as part of *Ruby* script. Most chips have library to use via C. This
difficulty can be solved by the way.

You can download repository to develop, and if you need this *Python* script then tell me,
i can share it via mail. Since you can test system, the script can run on PC. You **DO NOT NEED**
*single-board computer* to test.

## Install
`ruby -v # 2.4.1`

`mysql --version # 5.7.21`

(**Only development mode**)
* Project is runnable for both Linux and Windows.
You can use `rvm` to install suitable *ruby* version in Linux.

After you installed *ruby* and *mysql* then lets move:

* Our working directory is : `../proSen_mmd/`, don't forget.

        $ sudo gem install bundler # lets install it to install gems which our project needs
        $ sudo bin/bundle install # now using the '/Gemfile', we'll install gem which are dependencies

* Some configurations need:

In `/config/database.yml` you must type requirements, 
        
        default: &default
          adapter: mysql2
          encoding: utf8
          pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
          username: ## MySQL Username
          password: ## MySQL password
          socket: /var/run/mysqld/mysqld.sock
        
        development:
          <<: *default
          database: proSen_mmd

In `/config/initializers/constants_and_globals.rb` you must define your *IP_PATH*
as directory, project will use it. Then you will see here, *PIN_LIST* is list of PIN numbers on your
single-board computer which sensors can connect.
*INI_PORT* and *MASTER_PORT* can remain as default:

        # CONSTANTS DEFINITIONS
        #
        # IP_PATH => Directory of all .json files. It must be defined default !!
        #
        # PIN_LIST => It contains pins which are on the devices and
        # sensors are connected. Also, it must be defined default!!
        #
        IP_PATH = # YOUR DIRECTORY PATH for proSen USAGE
        SAVE_FILE_PATH = IP_PATH + 'save_file.json'.freeze
        BOUND_PATH = IP_PATH + 'bounds.json'.freeze
        PIN_LIST = %w[11_13 16_18 29_31].freeze
        INI_PORT = 9000
        MASTER_PORT = 5554
        ##

* Lets create our database and `tmp` directory (already you are in `../proSen_mmd/`):

        $ bin/rails db:drop # Drop if any database has same name
        
        $ bin/rails db:create # Database is created
        
        $ bin/rails db:migrate # The database model is migrated.
        
        $ bin/rails db:seed # And '.sql' scripts integrated to database
       
        $ bin/rails tmp:create # Created our 'tmp' directory
 
* Now you're ready, but for what? No deployment because we've no wep-pages. So, you have to use
`/bin/rails console` option. In here, you can test methods and classes. The methods can be seen
in scripts at `/lib/methodsLib` directory. Some of for example:

        scan_devices # Scans local network to find single-borard computers. Computers
                     # must be wait this request on 9000 port.
        
        master_ip_set(ip) # Set master device's IP.
        
        read_all_ip # Get all detected IPs after <scan_devices> operation
        
        slave_ip_add_del(ip_array, mod) # Add or remove slave device's IP
        
        read_slaves_ip # Get slave device's IP
        
        prepare_start_package # Prepare JSON type package to start system.
                              # It contains configurations
                              
        on_off_system(command, master_ip) # With this, you can start/stop system
        
* For more, you can investigate scripts. But, don't forget you have to work in `bin/rails console`

## Conclusion
At the end, the man will die. But before that, lets conclude README..

*proSen MMD* is so useful tool to monitor temperature and humidity of our environment
and process the data stored. It is really cheap way to do this. Because *single-board computers* are cheap,
a *PC* can serve RubyOnRails is cheap, *sensors* are generally cheap, *proSen MMD* is free
(but now, otherwise it'll be cheap :] ), *MySQL* is free and so on. As a result,
this system is cheap and so effective.

Database model and back-end stuffs are completed, mostly. After make web interface and
*single-board computer* side script, it can be used.  

### Interesting, But Not Completed :/
You're right. Maybe you don't want to pay time to develop this project. Understandable. If you
wanna try after completed, you can follow repository. Hopefully, it'll be completed, soon. 

***
### Contact
Any question, any suggestion, or just to say "hi!", you can use it:

**dore.fy@gmail.com**        
