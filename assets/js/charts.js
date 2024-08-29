import ApexCharts from 'apexcharts';

let ChartHooks = {};

ChartHooks.ApexChart = {
  mounted() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    
    const options = {
        chart: {
            type: 'line',
            height: '100%',
            zoom: {
                enabled: true,
                type: 'xy'
            },
            toolbar: {
                show: true,
                tools: {
                    download: true,
                    selection: true,
                    zoom: true,
                    zoomin: true,
                    zoomout: true,
                    pan: true,
                    reset: true
                },
                autoSelected: 'zoom'
            },
            foreColor: '#ffffff' // This sets the base text color for the chart
        },
        series: [
            {
                name: 'Total Revenue',
                data: chartData.total_revenue
            },
            {
                name: '6-Week Revenue',
                data: chartData.six_week_revenue
            }
        ],
        xaxis: {
          type: 'datetime',
          labels: {
              style: {
                  colors: '#ffffff',
                  fontSize: '14px' // Increase x-axis label font size
              }
          }
        },
        yaxis: {
            labels: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                },
                style: {
                  colors: '#ffffff',
                  fontSize: '14px' // Increase y-axis label font size
              }
            }            
        },
        tooltip: {
            x: {
                format: 'dd MMM yyyy'
            },
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        },
        legend: {
            position: 'top'
        },
        colors: ['#008FFB', '#00E396']
    };

    const chart = new ApexCharts(this.el, options);
    chart.render();

    this.handleEvent("updateChartData", (data) => {
        chart.updateSeries([
            { data: data.total_revenue },
            { data: data.six_week_revenue }
        ]);
    });
}
}

export default ChartHooks;