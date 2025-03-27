from diagrams import Diagram, Cluster
from diagrams.custom import Custom
from diagrams.onprem.vcs import Gitlab
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.iac import Ansible

with Diagram("Raspberry Pi GitLab Stack", show=True, direction="TB"): 
    with Cluster("Raspberry Pi GitLab", graph_attr={"bgcolor": "lightblue"}):
        rpi = Custom(" ", "./src/arch_diagrams/assets/raspberry-pi.png")
        gitlab = Gitlab("GitLab Server")
        grafana = Grafana("Grafana")
        prometheus = Prometheus("Prometheus")
        ansible = Ansible("Ansible")

        rpi - [ gitlab, grafana, prometheus, ansible]

with Diagram("Raspberry Pi RetroPie Stack", show=True,  direction="TB"):
    with Cluster("Raspberry Pi RetroPie" ,graph_attr={"bgcolor": "lightblue"}):
        rpi2 = Custom(" ", "./src/arch_diagrams/assets/raspberry-pi.png")
        retro = Custom(" ", "./src/arch_diagrams/assets/retro-pi.svg")
        grafana = Grafana("Grafana")
        prometheus = Prometheus("Prometheus")
        ansible = Ansible("Ansible")
        
        rpi - [ gitlab, grafana, prometheus, ansible]