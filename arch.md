RIP (working title)
===================

[rip] is a prioritized task management system that can be used to build, integrate, manage tasks, etc. One of the fundamental tennets of this software is to integrate seamlessly with git. All jobs must be defined in files that can be pushed via git repos. Jobs will need some type of local state (config file MVP?) which defines the repo and branch. The jobs repo will be separate from the [rip] repo by default.

Dependencies
============
- ORM 
-- activerecord gem probably
- DB
-- mysql probably, maybe reddis
- Front end 
-- grape for API?
-- sinatra for Front end? rack cascade?
-- something that provides webservices
-- internal shim
- Auth manager
-- maybe basic auth from grape for MVP
-- internal shim
- Shell manager
-- open4 maybe
-- internal shim
- Git manager
-- git gem probably
-- internal shim
- Cron manager
-- whenever gem maybe if we want it to actually write the jobs
-- cron parser gem maybe
-- internal shim
- State machine
-- statemachine gem?
-- internal shim
- Task manager
-- custom gem or internal code that finds and executes the states
- Email gem
-- mail?
-- internal shim

MVP
===
- packaged as a gem + deps
- rails-like or scaffold-type command to set up your project
- read and parse a job definition file

Post MVP
========
- git flow integration?
