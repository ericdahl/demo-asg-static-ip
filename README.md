# demo-asg-static-ip

AWS demo showing an AutoScaling Group with a static IP.

Implemented via:
- static Elastic Network Interface with specific IP
- ASG with Launch Template
- Launch Template referencing ENI

Notes:
- ASG size must be 1; 2nd instance fails

Use cases:
- DNS with resiliency
- some distributed databases
