package controller;
import db.Message;
import db.UserContract;
import sugoi.form.ListData;
import sugoi.form.validators.EmailValidator;
import sugoi.form.elements.*;
import sugoi.form.Form;

class Messages extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.canAccessMessages()) throw Redirect("/");
	}
	
	@tpl("messages/default.mtt")
	function doDefault() {
		
		var form = new Form("msg");		
		
		var senderName = "";
		var senderMail = "";
		
		if (App.current.session.data.whichUser == 1 && app.user.email2 != null) {
			senderMail = app.user.email2;
			senderName = app.user.firstName2 + " " + app.user.lastName2;
			
		}else {				
			senderMail = app.user.email;
			senderName = app.user.firstName + " " + app.user.lastName;
		}
		
		var lists = getLists();
		form.addElement( new StringInput("senderName", "Nom expéditeur",senderName,true));
		form.addElement( new StringInput("senderMail", "Email expéditeur",senderMail,true));
		form.addElement( new StringSelect("list", "Destinataires",lists,null,false,null,"style='width:500px;'"));
		form.addElement( new StringInput("subject", "Sujet :","",false,null,"style='width:500px;'") );
		form.addElement( new TextArea("text", "Message :", "", false, null, "style='width:500px;height:350px;'") );
		
		if (form.checkToken()) {
			
			var listId = form.getElement("list").value;
			var dest = getSelection(listId);
			var mails = [];
			for ( d in dest) {
				if (d.email != null) mails.push(d.email);
				if (d.email2 != null) mails.push(d.email2);
			}
			
			//throw mails;
			
			//send mail confirmation link
			var e = new ufront.mail.Email();		
			e.setSubject(form.getValueOf("subject"));
			e.bcc(Lambda.map(mails, function(m) return new ufront.mail.EmailAddress(m)));
			
			e.from(new ufront.mail.EmailAddress(App.config.get("default_email"),form.getValueOf("senderName")));		
			e.replyTo(new ufront.mail.EmailAddress(form.getValueOf("senderMail"), form.getValueOf("senderName")));
			
			////sender : default email ( explicitly tells that the server send an email on behalf of the user )
			//e.setHeader("Sender", App.config.get("default_email"));
			
			var text :String = form.getValueOf("text");
			var html = app.processTemplate("mail/message.mtt", { text:text,group:app.user.amap,list:getListName(listId) });		
			e.setHtml(html);
			
			app.event(SendEmail(e));
			
			if (!App.config.DEBUG){
				App.getMailer().send(e);	
			}
			
			
			var m = new db.Message();
			m.sender = app.user;
			m.title = e.subject;
			m.body = e.html;
			m.date = Date.now();
			m.amap = app.user.amap;
			m.recipientListId = listId;
			m.insert();
			
			throw Ok("/messages", "Le message a bien été envoyé");
		}
		
		view.form = form;
		
		if (app.user.isAmapManager()) {
			view.sentMessages = Message.manager.search($amap == app.user.amap, {orderBy:-date,limit:20}, false);
		}else {
			view.sentMessages = Message.manager.search($sender == app.user && $amap == app.user.amap, {orderBy:-date,limit:20}, false);	
		}
		
	}
	
	@tpl("messages/message.mtt")
	public function doMessage(msg:Message) {
		if (!app.user.isAmapManager() && msg.sender.id != app.user.id) throw Error("/", "accès non autorisé");
		
		view.list = getListName(msg.recipientListId);
		view.msg = msg;
		
	}
	
	function getLists() :FormData<String>{
		var out = [
			{value:'1', label:'Tout le monde' },
			{value:'2', label:'Le bureau : les responsables + contrats + adhésions' },			
		];
		
		out.push( { value:'3', label:'TEST : moi + conjoint(e)' } );
		out.push( { value:'4', label:'Adhérents sans contrat/commande' } );
		if(app.user.amap.hasMembership()) out.push( { value:'5', label:'Adhésions à renouveller' } );
		
		
		var contracts = db.Contract.getActiveContracts(app.user.amap,true);
		for ( c in contracts) {
			out.push({value:'c'+c.id,label:'Souscripteurs '+c.toString()});
		}
		return out ;
		
	}
	
	/**
	 * get list name from id
	 * @param	listId
	 */
	function getListName(listId:String) {
		var l = getLists();
		
		for (ll in l) {
			if (ll.value == listId) return ll.label;
		}
		
		return null;
		
	}
	
	function getSelection(listId:String) {
		if (listId.substr(0, 1) == "c") {
			//contrats
			var contract = Std.parseInt(listId.substr(1));
			
			var pids = db.Product.manager.search($contractId == contract, false);
			var pids = Lambda.map(pids, function(x) return x.id);
			var up = db.UserContract.manager.search($productId in pids, false);
			
			
			var users = [];
			for ( order in up) {
				if (!Lambda.has(users, order.user)) {
					users.push(order.user);	
					
					if (order.user2 != null) {
						users.push(order.user2);
					}
				}
			}
			return users;
			
		}else {
			var out = [];
			switch(listId) {
			case "1": 		
				//tout le monde
				out =  Lambda.array(app.user.amap.getMembers());
					
			case "2":
				
				var users = [];
				users.push(app.user.amap.contact);
				for ( c in db.Contract.manager.search($amap == app.user.amap)) {
					if (!Lambda.has(users, c.contact)) {
						users.push(c.contact);
					}
				}
				
				//ajouter les autres personnes ayant les droits Admin ou Gestion Adhérents ou Gestion Contrats
 				for (ua in Lambda.array(db.UserAmap.manager.search($rights != null && $amap == app.user.amap, false))) {
 					if (ua.hasRight(AmapAdmin) || ua.hasRight(Membership) || ua.hasRight(ContractAdmin())) {
 						if (!Lambda.has(users, ua.user)) users.push(ua.user);
 					}
 				}
				
				out = users;
			
			case "3":
				//moi
				return [app.user];
			case "4":
				return Lambda.array(db.User.getUsers_NoContracts());
			case "5":
				return Lambda.array(db.User.getUsers_NoMembership());
			}
			
			return out;
			
		}
	}
	
	

	
	
}