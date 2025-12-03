// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "chartkick"
import "Chart.bundle"
Chartkick.options = {
  library: {
    plugins: {
      tooltip: {
        mode: 'index',
        intersect: false,
        position: 'nearest',
        itemSort: function(a, b) {
          var order = { 2: 0, 1: 1, 0: 2 };  // fyi, order is life event, total assets, savings
          return order[a.datasetIndex] - order[b.datasetIndex];
        },
        callbacks: {
          label: function(context) {
            var label = context.dataset.label || '';
            var value = context.parsed.y;
            if (label === 'Life Event' && window.eventNamesMap) {
              var eventName = window.eventNamesMap[context.label];
              if (eventName) {
                return 'Event: ' + eventName;
              }
              return null;
            }
            return label + ': ¥' + value.toLocaleString();
          }
        }
      }
    }
  }
};
