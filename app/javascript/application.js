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
        callbacks: {
          label: function(context) {
            var label = context.dataset.label || '';
            var value = context.parsed.y;
            if (label === 'Life Event' && window.eventNamesMap) {
              var eventName = window.eventNamesMap[context.label];
              if (eventName) {
                return eventName + ': ¥' + value.toLocaleString();
              }
            }
            return label + ': ¥' + value.toLocaleString();
          }
        }
      }
    }
  }
};
