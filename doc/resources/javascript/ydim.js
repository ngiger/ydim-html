function sbsm_encode(value)
{
  // this function provides an Encoding-Hack: because encodeURIComponent returns 
  // UTF-8 encoded values and because for some reasone we need to encode twice 
  // anyway, we first encode in native charset.
	value = dojo.string.encodeAscii(value);
  value = value.replace(/\//g, '%2f')
	value = encodeURIComponent(value);
	return value;
}

function reload_form(form_id, server_event)
{
	var form;
	var evt_field;
	if((form = document.getElementById(form_id)) && (evt_field = document.getElementById("event")))
	{
		evt_field.value = server_event;
		dojo.io.bind({
			url: form.action,
			formNode: form,
			load: function(type, data, event) { 
				form.parentNode.innerHTML = data;
			},
			mimetype: "text/html"
		});
	}
}
function reload_list(list_id, url)
{
	var list;
	if(list = document.getElementById(list_id))
	{
		dojo.io.bind({
			url: url,
			load: function(type, data, event) { 
				list.parentNode.innerHTML = data;
			},
			mimetype: "text/html"
		});
	}
}
function reload_data(url)
{
	dojo.io.bind({
		url: url,
		load: function(type, data, event) {
			var key, val, item;
			for(key in ajaxResponse) { 
				if(item = document.getElementById(key))
				{
					if(item.value)
					{
						item.value = ajaxResponse[key];
					}
					else
					{
						item.innerHTML = ajaxResponse[key];
					}
				}
			}
		},
		mimetype: "text/javascript"
	});
}
