var x = document.getElementsByClassName('panel-heading');
x[0].style.backgroundColor = '#222D32';
x[1].style.backgroundColor = '#222D32';
x = document.getElementsByClassName('panel-body');
x[0].style.backgroundColor = '#222D32';
x[1].style.backgroundColor = '#222D32';
var net = document.getElementById('network');
var content = document.getElementsByClassName('content')[0];
net.style.height = window.innerHeight * 0.98 + 'px';
content.style.padding = '1px';
document.getElementsByClassName('panel-default')[0].style.borderWidth = '0px';
document.getElementsByClassName('panel-body')[0].style.borderWidth = '0px';
document.getElementsByClassName('panel-heading')[0].style.borderWidth = '0px';
document.getElementsByClassName('panel-default')[1].style.borderWidth = '0px';
document.getElementsByClassName('panel-body')[1].style.borderWidth = '0px';
document.getElementsByClassName('panel-heading')[1].style.borderWidth = '0px';
var tour = new Tour({
    backdrop: true,
    backdropPadding: 5,
    onShown: function (tour) {
        var backdrop = document.getElementsByClassName('tour-backdrop')[0];
        backdrop.style.opacity = '.3';
        backdrop.style.animation = 'pulse 1s';
    },
    onEnd: function (tour) {
        setCookie('BN_tutorial','true',7); 
    },
    steps: [
        {
            element: '#collapseExample',
            title: 'Load Files',
            content: 'Welcome to the shinyDBNet tutorial! Upload your Bayesian Network files here to get started'
        },
        {
            element: '#fileInput1',
            title: 'Loading the nodes',
            content: 'First, upload the information about the nodes of your network'
        },
        {
            element: '#fileInput2',
            title: 'Loading the connections',
            content: 'Then, upload the information about the relationships between the nodes'
        },
        {
            element: '#preTrained',
            title: 'Loading the pre-trained Bayesian Network',
            content: 'You can also skip the previous steps by playing with a pre-trained network',
            onNext: function (tour) {
                tour.end();
            }
        },
        {
            element: '#network',
            title: 'Displaying the network',
            content: 'At this point, you should be able to see your network here',
            placement: 'left'
        },
        {
            element: '#fileInput3',
            title: 'Loading the data',
            content: 'In order to start inferencing, the data must be loaded and the Bayesian Network must be learned',
            onNext: function (tour) {
                tour.end();
            }
        },
        {
            element: '',
            title: 'Setting the evidence on a single node',
            content: 'Double click on a node to see its prior distribution and to set the known evidence, if available',
            orphan: true
        },
        {
            element: '#querySection',
            title: 'Querying',
            content: 'Click here to perform a query on the selected node'
        },
        {
            element: '#evidenceMenuButton',
            title: 'Setting the evidence on multiple nodes at the same time',
            content: 'You can also set the evidence on all the known nodes at once. Click here to open the evidence menu'
        }
    ]
});