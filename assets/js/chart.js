// Apex Charts
import ApexCharts from 'apexcharts';

let Hooks = {};

Hooks.ApexChart = {
  mounted() {
    // Parse initial chart data from the element's dataset
    const initialData = JSON.parse(this.el.dataset.chartData);

    // Initialize the chart
    this.chart = new ApexCharts(this.el, {
      chart: {
        type: 'line',
        id: 'mainChart',
        responsive: true,
        height: '100%',          // Ensures the chart takes 100% of the div's height
        width: '100%',           // Ensures the chart takes 100% of the div's width
        zoom: {
          type: 'x',
          enabled: true,
          autoScaleYaxis: true
        },
        toolbar: {
          autoSelected: 'zoom',
          tools: {
            zoomin: true,
            zoomout: true,
            pan: true,
            reset: true
          }
        }
      },
      series: [
        {
          name: 'Total Revenue',
          data: initialData.total_revenue
        },
        {
          name: 'Six Week Revenue',
          data: initialData.six_week_revenue
        }
      ],
      xaxis: {
        type: 'datetime',
        labels: {
          style: {
            colors: '#f0f3f7',  // Change this to your desired color for X-axis labels
          }
        }
      },
      yaxis: {
        labels: {
          style: {
            colors: '#f0f3f7',  // Change this to your desired color for Y-axis labels
          }
        }
      }
    });

    // Render the chart
    this.chart.render();
  },

  updated() {
    // Update the chart with new data
    const updatedData = JSON.parse(this.el.dataset.chartData);

    this.chart.updateSeries([
      {
        name: 'Total Revenue',
        data: updatedData.total_revenue
      },
      {
        name: 'Six Week Revenue',
        data: updatedData.six_week_revenue
      }
    ]);
  }
};

export default ChartHooks;