#!/usr/bin/env ruby
# encoding: utf-8
# Html::View::Invoice -- ydim -- 16.01.2006 -- hwyss@ywesee.com

require 'ydim/html/view/template'
require 'htmlgrid/form'
require 'htmlgrid/inputcheckbox'
require 'htmlgrid/inputdate'
require 'htmlgrid/errormessage'
require 'htmlgrid/select'
require 'htmlgrid/textarea'

module YDIM
	module Html
		module View
class SpanValue < HtmlGrid::Value
	def init
		super
		@attributes.store('id', @name)
	end
	def to_html(context)
		context.span(@attributes) { number_format escape(@value) }
	end
end
class ItemList < HtmlGrid::List
	COMPONENTS = {
		[0,0]	=>	:time,
		[1,0]	=>	:text,
		[2,0]	=>	:quantity,
		[3,0]	=>	:unit,
		[4,0]	=>	:price,
		[5,0]	=>	:total_netto,
		[6,0]	=>	:delete,
	}
	CSS_ID = 'items'
	CSS_MAP = {
		[0,0]	=>	'standard-width',
		[5,0]	=>	'right',
	}
	COMPONENT_CSS_MAP = {
		[1,0]	=>	'extralarge',
		[2,0]	=>	'small',
		[3,0]	=>	'medium',
		[4,0]	=>	'medium',
	}
	DEFAULT_CLASS = HtmlGrid::InputText
	SORT_DEFAULT = nil
	ajax_inputs :text, :quantity, :unit, :price
	def compose_footer(offset)
		link = HtmlGrid::Button.new(:create_item, @model, @session, self)
		args = { :unique_id => @session.state.model.unique_id }
		url = @lookandfeel.event_url(:ajax_create_item, args)
		link.set_attribute('onClick', "reload_list('items', '#{url}');")
		@grid.add(link, *offset)
	end
	def delete(model)
		link = HtmlGrid::Link.new(:delete, model, @session, self)
		args = {
			:unique_id	=>	@session.state.model.unique_id,
			:index			=>	model.index,
		}
		url = @lookandfeel.event_url(:ajax_delete_item, args)
		link.href = "javascript: reload_list('items', '#{url}')"
		link
	end
	def time(model)
		if(time = model.time)
			@lookandfeel.format_time(model.time)
		end
	end
	def total_netto(model)
		val = SpanValue.new(:total_netto, model, @session, self)
		val.css_id = "total_netto#{model.index}"
		val
	end
end
class InvoiceTotalComposite < HtmlGrid::Composite
	COMPONENTS = {
		[0,0]	=>	:total_netto,
		[0,1,0]	=>	:vat_rate,
		[0,1,1]	=>	:vat,
		[0,2]	=>	:total_brutto,
	}
	CSS_ID = 'total'
	CSS_MAP = {
		[1,0,1,3]	=>	'right',
	}
	DEFAULT_CLASS = SpanValue
	LABELS = true
  def vat_rate(model)
		if(vat = model.vat)
			sprintf(@lookandfeel.lookup(:vat_rate), 100*model.vat/model.total_netto)
		end
  end
end
class InvoiceInnerComposite < HtmlGrid::Composite
	include HtmlGrid::ErrorMessage
	links :debitor, :name, :email
  COMPONENTS = {
    [0,0]		=>	:unique_id,
    [0,1,0]	=>	:debitor_name,
    [1,1,1]	=>	'dash',
    [1,1,2]	=>	:debitor_email,
    [0,2]		=>	:description,
    [0,3]		=>	:date,
    [1,3]		=>	:payment_period,
    [0,4]		=>	:currency,
    [0,5]		=>	:precision,
    [0,6]   =>  :suppress_vat,
  }
	COMPONENT_CSS_MAP = {
		[0,2]	=>	'extralarge',
		[0,5]	=>	'small',
	}
	DEFAULT_CLASS = HtmlGrid::Value
	LABELS = true
	SYMBOL_MAP = {
		:date					      =>	HtmlGrid::InputDate,
		:description	      =>	HtmlGrid::InputText,
    :invoice_interval   =>  HtmlGrid::Select,
    :reminder_subject   =>  HtmlGrid::InputText,
	}
	def init
		super
		error_message
	end
	def currency(model)
		select = HtmlGrid::Select.new(:currency, model, @session, self)
		if(model.unique_id)
			select.set_attribute('onChange', "reload_form('invoice', 'ajax_invoice');")
		end
		select
	end
	def debitor_email(model)
		email(model.debitor)
	end
	def debitor_name(model)
		link = name(model.debitor)
		link.label = true
		link
	end
  def payment_period(model)
    @lookandfeel.lookup(:payment_period, model.payment_period.to_i)
  end
	def precision(model)
		input = HtmlGrid::InputText.new(:precision, model, @session, self)
		if(model.unique_id)
			input.set_attribute('onChange', "reload_form('invoice', 'ajax_invoice');")
		end
		input
	end
  def suppress_vat(model)
    input = HtmlGrid::InputCheckbox.new(:suppress_vat, model, @session, self)
		if(model.unique_id)
			input.set_attribute('onClick', "reload_form('invoice', 'ajax_invoice');")
		end
    input
  end
end
class InvoiceComposite < HtmlGrid::DivComposite
	include HtmlGrid::FormMethods
	FORM_ID = 'invoice'
	COMPONENTS = {
		[0,0]	=>	InvoiceInnerComposite,
		[0,1]	=>	:items,
		[0,2]	=>	InvoiceTotalComposite,
		[0,3]	=>	:submit,
		[1,3]	=>	:pdf,
		[2,3]	=>	:send_invoice,
	}
	CSS_MAP = {
		3	=>	'padded'
	}
	EVENT = :update
	def init
		if(@model.unique_id.nil?)
			@components = {
				[0,0]	=>	components[[0,0]],
				[0,1]	=>	:submit,
			}
			@css_map = { 1 => 'padded' }
		elsif(@model.items.empty?)
			@components = {
				[0,0]	=>	components[[0,0]],
				[0,1]	=>	:items,
				[0,2]	=>	:submit,
			}
			@css_map = { 2 => 'padded' }
		end
		super
	end
	def hidden_fields(context)
		super << context.hidden('unique_id', @model.unique_id)
	end
	def items(model)
		ItemList.new(model.items, @session, self)
	end
	def pdf(model)
		button = HtmlGrid::Button.new(:pdf, model, @session, self)
		url = @lookandfeel._event_url(:pdf, {:unique_id => model.unique_id})
		button.set_attribute('onClick', "document.location.href='#{url}'")
		button
	end
	def send_invoice(model)
    button(:send_invoice, model)
  end
  def button(key, model)
		button = HtmlGrid::Button.new(key, model, @session, self)
		url = @lookandfeel._event_url(key, {:unique_id => model.unique_id})
		button.set_attribute('onClick', 
      "this.form.event.value='#{key}'; this.form.submit()")
		button
	end
end
class Invoice < Template
	CONTENT = InvoiceComposite
	def init
		css_map[1] = @model.status
		super
	end
end
		end
	end
end
