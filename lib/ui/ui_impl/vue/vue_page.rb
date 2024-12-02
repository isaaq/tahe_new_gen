# frozen_string_literal: true

class VuePage
  attr_accessor :type
  def default_page
    <<~EOS
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vue Single Page Example</title>
  <!-- Include Vue.js from CDN -->
  <script src="https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.js"></script>
  #import{}
</head>
<body>
  <!-- Vue App Root -->
  <div id="app">
    #template{}
  </div>

  <script>
    const { createApp } = Vue;

    createApp({
      data() {
        return {
          #data{}
        };
      },
      methods: {
        #methods{}
      }
    }).mount('#app');
  </script>
</body>
</html>
    EOS
  end
end
