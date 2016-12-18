import haxe.macro.Expr;
import haxe.macro.Context;
import StringTools;

class MyMacros {
	/* based on 
	http://code.haxe.org/category/macros/add-git-commit-hash-in-build.html 
	http://stackoverflow.com/questions/8611486/how-to-get-the-last-commit-date-for-a-bunch-of-files-in-git*/
	public static macro function getGitCommitDate():haxe.macro.ExprOf<String> {
	    #if !display
	    var process = new sys.io.Process('git', ['log', '-1', '--format=%ci']);
	    if (process.exitCode() != 0) {
	      var message = process.stderr.readAll().toString();
	      var pos = haxe.macro.Context.currentPos();
	      Context.error("Cannot execute `git log -1 --format=%ci`. " + message, pos);
	    }
	    
	    // read the output of the process
	    var commitDate:String = process.stdout.readLine();
	    commitDate = StringTools.replace(commitDate, " ", ".");
	    commitDate = StringTools.replace(commitDate, "-", ".");
	    commitDate = StringTools.replace(commitDate, ":", ".");
	    commitDate = commitDate.substr(0,16);
	    
	    // Generates a string expression
	    return macro $v{commitDate};
	    #else 
	    // `#if display` is used for code completion. In this case returning an
	    // empty string is good enough; We don't want to call git on every hint.
	    var commitDate:String = "";
	    return macro $v{commitDate};
	    #end
  	}

	public static macro function getGitBranch():haxe.macro.ExprOf<String> {
	    #if !display
	    var process = new sys.io.Process('git', ['symbolic-ref', 'HEAD', '--short']);
	    if (process.exitCode() != 0) {
	      var message = process.stderr.readAll().toString();
	      var pos = haxe.macro.Context.currentPos();
	      Context.error("Cannot execute `git symbolic-ref HEAD --short`. " + message, pos);
	    }
	    
	    // read the output of the process
	    var commitBranch:String = process.stdout.readLine();
	    commitBranch = StringTools.replace(commitBranch, "-", ".");
	    commitBranch = StringTools.replace(commitBranch, "_", ".");
	    
	    // Generates a string expression
	    return macro $v{commitBranch};
	    #else 
	    // `#if display` is used for code completion. In this case returning an
	    // empty string is good enough; We don't want to call git on every hint.
	    var commitBranch:String = "";
	    return macro $v{commitBranch};
	    #end
  	}

}
