package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import react.product.Product;

/**
 * A User order
 * @author fbarbut
 */
class Order extends react.ReactComponentOfPropsAndState<{order:UserOrder,onUpdate:UserOrder->Void,parentBox:react.order.OrderBox},{order:UserOrder,inputValue:String}>
{
	var hasPayments :Bool;
	var currency : String;

	public function new(props) 
	{
		super(props);
		state = {order:props.order,inputValue:null};
		hasPayments = props.parentBox.props.hasPayments;
		currency = props.parentBox.props.currency;
		
		if (state.order.productUnit == null) state.order.productUnit = Piece;
		if (state.order.productQt == null) state.order.productQt = 1;
		
		state.inputValue = if (state.order.productHasFloatQt || state.order.productHasVariablePrice){
			Std.string(round(state.order.quantity * state.order.productQt));
		}else{
			Std.string(state.order.quantity);
		}
	}
	
	override public function render(){
		var o = state.order;
		/*var unit = if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-1">${Formatting.unit(o.productUnit)}</div>');
		}else{
			jsx('<div className="col-md-1"></div>');
		}*/
		
		/*
		//use smart qt only if hasFloatQt
		var productName = if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-3">${o.productName}</div>');
		}else{			
			jsx('<div className="col-md-3">${o.productName} ${o.productQt} ${Formatting.unit(o.productUnit)}</div>');
		}
		*/
		/*var productName = if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-3">${o.productName}</div>');*/
		
		var input =  if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="input-group">
					<input type="text" className="form-control input-sm text-right" value="${state.inputValue}" onChange=${onChange} onKeyPress=${onKeyPress}/>
					<div className="input-group-addon">${Formatting.unit(o.productUnit)}</div>
				</div>');	
		}else{
			jsx('<div className="input-group">
					<input type="text" className="form-control input-sm text-right" value="${state.inputValue}" onChange=${onChange} onKeyPress=${onKeyPress}/>
				</div>');
		}
		
//		var s = {backgroundImage:"url(\""+o.productImage+"\")", width:"32px", height:"32px"};

		return jsx('<div className="productOrder row">
			<div className="col-md-4">
				<$Product productInfo=${o.product} />
			</div>

			<div className="col-md-1 ref">
				${o.productRef}
			</div>

			<div className="col-md-1">
				${round(o.quantity * o.productPrice)}&nbsp;${currency}
			</div>
			
			<div className="col-md-2">
				$input			
				${makeInfos()}
			</div>
			
			${paidInput()}
						
			<div className="col-md-2">
				Alterné avec X <br/>
				Inverser alternance <input type="checkbox" name="paid" value="1" onChange=$onChangeInvert />
			</div>
	

		</div>');
	}
	
	function round(f){
		return Formatting.formatNum(f);
	}

	function paidInput(){
		if(hasPayments) return null;
		if(state.order.paid){
			return jsx('<div className="col-md-1">Payé <input type="checkbox" name="paid" value="1" checked="1" onChange=${onChangePaid} /></div>');
		}else{
			return jsx('<div className="col-md-1">Payé <input type="checkbox" name="paid" value="1" onChange=${onChangePaid} /></div>');
		}
	}
	
	function makeInfos(){
		var o = state.order;
		return if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="infos">
				<b> ${round(o.quantity)} </b> x <b>${o.productQt} ${Formatting.unit(o.productUnit)}</b > ${o.productName}				
			</div>');
		}else{
			null;
		}
	}
	
	function onChange(e:js.html.Event){
		e.preventDefault();		
		var value :String = untyped (e.target.value == "") ? "0" : e.target.value;
		state.inputValue = value;
		var v = Formatting.parseFloat(value);
		var o = state.order;
		if ( o.productHasFloatQt || o.productHasVariablePrice){
			//if has float qt or variablePrice, the value is a smart qt, so we need re-compute the quantity
			o.quantity = v / o.productQt;
		}else{
			o.quantity = v;	
		}
		
		this.setState(state);
		if (props.onUpdate != null) props.onUpdate(state.order);
	}

	function onChangePaid(e:js.html.Event){
		//var value:Bool = untyped (e.target.value == "") ? "0" : e.target.value;
		trace( untyped e.target.value , untyped e.target.checked);
		state.order.paid = untyped e.target.checked;
		trace("state after PAID",state);
		this.setState(state);
		if (props.onUpdate != null) props.onUpdate(state.order);
	}

	function onChangeInvert(e:js.html.Event){

	}
	
	function onKeyPress(event:js.html.KeyboardEvent){
		/*if(event.key == 'Enter'){
			trace('enter !');
		}*/
	}
}