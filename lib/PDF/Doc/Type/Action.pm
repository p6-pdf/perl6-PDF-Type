use v6;

use PDF::DAO::Tie::Hash;

role PDF::Doc::Type::Action {...}

# See [PDF 1.7 TABLE 8.2 Destination syntax]
my subset NumNull of Any where { .does(Numeric) || !.defined };  #| UInt value or null
multi sub is-destination($page, 'XYZ', NumNull $left,
			 NumNull $top, NumNull $zoom)        { True }
multi sub is-destination($page, 'Fit')                       { True }
multi sub is-destination($page, 'FitH',  NumNull $top)       { True }
multi sub is-destination($page, 'FitV',  NumNull $left)      { True }
multi sub is-destination($page, 'FitR',  Numeric $left,
			 Numeric $bottom, Numeric $right,
			 Numeric $top )                      { True }
multi sub is-destination($page, 'FitB')                      { True }
multi sub is-destination($page, 'FitBH', NumNull $top)       { True }
multi sub is-destination($page, 'FitBV', NumNull $left)      { True }
multi sub is-destination(|c)                      is default { False }

my subset DestinationArray of Array where is-destination(|@$_);
subset PDF::Doc::Type::Action::Destination of PDF::DAO where DestinationArray | PDF::Doc::Type::Action; #| e.g. for Catalog /OpenAction entry

# /Type /Action

role PDF::Doc::Type::Action
    does PDF::DAO::Tie::Hash {

    # set [PDF 1.7 TABLE 8.17 Entries in a action style dictionary]
    use PDF::DAO::Tie;
    use PDF::DAO::Name;

    my subset Name-Action of PDF::DAO::Name where 'Action';
    has Name-Action $.Type is entry;

    my subset ActionSubtype of PDF::DAO::Name where
	'GoTo'         #| Go to a destination in the current document.
	|'GoToR'       #| (“Go-to remote”) Go to a destination in another document.
	|'GoToE'       #| (“Go-to embedded”; PDF 1.6) Go to a destination in an embedded file.
	|'Launch'      #| Launch an application, usually to open a file.
	|'Thread'      #| Begin reading an article thread.
	|'URI'         #| Resolve a uniform resource identifier.
	|'Sound'       #| (PDF 1.2) Play a sound.
	|'Movie'       #| (PDF 1.2) Play a movie.
	|'Hide'        #| (PDF 1.2) Set an annotation’s Hidden flag.
	|'Named'       #| (PDF 1.2) Execute an action predefined by the viewer application.
	|'SubmitForm'  #| (PDF 1.2) Send data to a uniform resource locator.
	|'ResetForm'   #| (PDF 1.2) Set fields to their default values.
	|'ImportData'  #| (PDF 1.2) Import field values from a file.
	|'JavaScript'  #| (PDF 1.3) Execute a JavaScript script.
	|'SetOCGState' #| (PDF 1.5) Set the states of optional content groups.
	|'Rendition'   #| (PDF 1.5) Controls the playing of multimedia content.
	|'Trans'       #| (PDF 1.5) Updates the display of a document, using a transition dictionary.
	|'GoTo3DView'  #| (PDF 1.6) Set the current view of a 3D annotation
	;

    has ActionSubtype $.S is entry(:required);

    proto sub coerce($,$) is export(:coerce) {*}

    multi sub coerce(Hash $dict is rw where { .<S> ~~ ActionSubtype }, PDF::Doc::Type::Action) {
	my $subclass = PDF::DAO.delegator.find-delegate( 'Action', $dict<S> );
	PDF::DAO.coerce($dict, $subclass);
    }

    multi sub coerce(Hash $dict is rw, PDF::Doc::Type::Action) is default {
	warn "unknown action subtype: $dict<S>"
	    if $dict<S>:exists;
	PDF::DAO.coerce($dict, PDF::Doc::Type::Action);
    }

    multi sub coerce(Hash $dict is rw, PDF::Doc::Type::Action::Destination) {
	coerce( $dict, PDF::Doc::Type::Action );
    }

    my subset NextActionArray of Array where { !.first( !*.isa(PDF::Doc::Type::Action) ) }
    my subset NextAction of Any where PDF::Doc::Type::Action | NextActionArray;

    multi sub coerce(Hash $actions, NextAction) {
      PDF::DAO.coerce( $_, PDF::Doc::Type::Action )
    }
    multi sub coerce(Array $actions, NextAction) {
      PDF::DAO.coerce( $actions[$_], PDF::Doc::Type::Action )
	  for $actions.keys;
    }

    has NextAction $.Next is entry(:&coerce);

    # todo remaining fields, TABLE 8.49 thru 8.51 etc

}
