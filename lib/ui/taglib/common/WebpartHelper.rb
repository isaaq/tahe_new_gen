module WebpartHelper
  def str_getdata(url, response)
    <<-EOF
      getdata() {
        axios
        .get('#{url}')
        .then(r => {
          #{response}
        })
        .catch(function (error) {
          console.log(error);
        });
      },
    EOF
  end

  def str_postdata(url, data, response)
    <<-EOF
      postdata() {
        axios
        .post('#{url}', #{data})
        .then(r => {
          #{response}
        })
        .catch(function (error) {
          console.log(error);
        });
      },
    EOF
  end

  def make_script(script)
    code = Util.find_var("@ex_codes")
    code << { name: "script", code: script }
  end
end
