# --
# HTML/Agent.pm - provides generic agent HTML output
# Copyright (C) 2001-2002 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: Agent.pm,v 1.27 2002-05-21 21:43:19 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::Agent;

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.27 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

# --
sub NavigationBar {
    my $Self = shift;
    my %Param = @_;

    my $LockData = $Param{LockData};
    my %LockDataTmp = %$LockData;
    $Param{LockCount} = $LockDataTmp{Count} || 0;
    $Param{LockToDo} = $LockDataTmp{ToDo} || 0;

    # create & return output
    return $Self->Output(TemplateFile => 'AgentNavigationBar', Data => \%Param);
}
# --
sub QueueView {
    my $Self = shift;
    my %Param = @_;
    my $QueueStrg = '';
    my $QueueID = $Param{QueueID} || 0;
    my $QueuesTmp = $Param{Queues};
    my @QueuesNew = @$QueuesTmp;
    my $QueueIDOfMaxAge = $Param{QueueIDOfMaxAge} || '?';
    $Self->{HighlightAge1} = $Self->{ConfigObject}->Get('HighlightAge1');
    $Self->{HighlightAge2} = $Self->{ConfigObject}->Get('HighlightAge2');
    $Self->{HighlightColor1} = $Self->{ConfigObject}->Get('HighlightColor1');
    $Self->{HighlightColor2} = $Self->{ConfigObject}->Get('HighlightColor2'); 
 
    # build queue string
    foreach my $QueueRef (@QueuesNew) {
        my %Queue = %$QueueRef;
        $Queue{MaxAge} = $Queue{MaxAge} / 60;
        # should i highlight this queue
        if ($QueueID eq $Queue{QueueID}) {
           $QueueStrg .= '<B>';
           $Param{SelectedQueue} = $Queue{Queue};
        }
        $QueueStrg .= "<A HREF=\"$Self->{Baselink}&Action=AgentQueueView&QueueID=$Queue{QueueID}\">";
        # should i highlight this queue
        if ($Queue{MaxAge} >= $Self->{HighlightAge2}) {
            $QueueStrg .= "<FONT COLOR=$Self->{HighlightColor2}>";
        }
        elsif ($Queue{MaxAge} >= $Self->{HighlightAge1}) {
            $QueueStrg .= "<FONT COLOR=$Self->{HighlightColor1}>";
        }
        # the oldest queue
        if ($Queue{QueueID} == $QueueIDOfMaxAge) {
            $QueueStrg .= "<BLINK>";
        }
        # QueueStrg
        $QueueStrg .= "$Queue{Queue} ($Queue{Count})";
        # the oldest queue
        if ($Queue{QueueID} == $QueueIDOfMaxAge) {
            $QueueStrg .= "</BLINK>";
        }
        # should i highlight this queue
        if ($Queue{MaxAge} >= $Self->{HighlightAge1}
              || $Queue{MaxAge} >= $Self->{HighlightAge2}) {
            $QueueStrg .= "</FONT>";
        }
        $QueueStrg .= "</A>";
        # should i highlight this queue
        if ($QueueID eq $Queue{QueueID}) {
           $QueueStrg .= '</B>';
        }
        $QueueStrg .= ' - ';
    }
    $Param{QueueStrg} = $QueueStrg;

    # create & return output
    return $Self->Output(TemplateFile => 'QueueView', Data => \%Param);
}
# --
sub TicketView {
    my $Self = shift;
    my %Param = @_;
    my $StdResponsesTmp = $Param{StdResponses};
    my %StdResponses = %$StdResponsesTmp;

    # do some html quoting
    foreach ('From', 'To', 'Cc', 'Subject', 'Priority', 'State') {
        $Param{$_} = $Self->Ascii2Html(Text => $Param{$_}, Max => 150, MIME => 1) || '';
    }
    $Param{Age} = $Self->CustomerAge(Age => $Param{Age}, Space => ' ');

    # do some text quoting
    $Param{Text} = $Self->Ascii2Html(
        NewLine => $Self->{ConfigObject}->Get('ViewableTicketNewLine') || 85,
        Text => $Param{Text}, 
        VMax => $Self->{ConfigObject}->Get('ViewableTicketLines') || 25,
    );
    # do link quoting
    $Param{Text} = $Self->LinkQuote(
        Text => $Param{Text},
    );

    # get MoveQueuesStrg
    $Param{MoveQueuesStrg} = $Self->OptionStrgHashRef(
        Name => 'DestQueueID',
        SelectedID => $Param{QueueID},
        Data => $Param{MoveQueues},
        OnChangeSubmit => $Self->{ConfigObject}->Get('OnChangeSubmit'),
    );

    # get StdResponsesStrg
    foreach (keys %StdResponses) {
       $Param{StdResponsesStrg} .= "\n<li><A HREF=\"$Self->{Baselink}&Action=AgentCompose&ResponseID=$_&".
       "TicketID=$Param{TicketID}\">" .
          "$StdResponses{$_}</A></li>\n";
    }


    # create & return output
    return $Self->Output(TemplateFile => 'TicketView', Data => \%Param);
}
# --
sub TicketZoom {
    my $Self = shift;
    my %Param = @_;

    # do some html quoting
    foreach ('Priority', 'State') {
        $Param{$_} = $Self->Ascii2Html(Text => $Param{$_}, Max => 50, MIME => 1) || '';
    }
    $Param{Age} = $Self->CustomerAge(Age => $Param{Age}, Space => ' ');
    $Param{Owner} = $Self->Ascii2Html(Text => $Param{Owner}, Max => 20) || ''; 

    # get MoveQueuesStrg
    $Param{MoveQueuesStrg} = $Self->OptionStrgHashRef(
        Name => 'DestQueueID',
        SelectedID => $Param{QueueID},
        Data => $Param{MoveQueues},
        OnChangeSubmit => $Self->{ConfigObject}->Get('OnChangeSubmit'),
    );

    # build article stuff
    $Param{ArticleStrg} = '';
    my $ArticleID = $Param{ArticleID} || '';
    my $BaseLink = $Self->{Baselink} . "&TicketID=$Self->{TicketID}&QueueID=$Self->{QueueID}";
    my $ArticleBoxTmp = $Param{ArticleBox};
    my @ArticleBox = @$ArticleBoxTmp;
    my $MoveQueues = $Param{MoveQueues};
    my $StdResponsesTmp = $Param{StdResponses};
    my %StdResponses = %$StdResponsesTmp;
    my $ThreadStrg = '<FONT SIZE="-1">';
    my $Counter = '';
    my $Space = '';
    my $CounterArray = 0;
    my $LastSenderType = '';
    my $LastCustomerArticleID;
    my $LastCustomerArticle = $#ArticleBox;

    # get StdResponsesStrg
    foreach (keys %StdResponses) {
       $Param{StdResponsesStrg} .= "\n<li><A HREF=\"$BaseLink&Action=AgentCompose&".
        "ResponseID=$_&ArticleID=$ArticleID\">$StdResponses{$_}</A></li>\n";
    }

    foreach my $ArticleTmp (@ArticleBox) {
        my %Article = %$ArticleTmp;
        # if it is a customer article
        if ($Article{SenderType} eq 'customer') {
            $LastCustomerArticleID = $Article{'ArticleID'};
            $LastCustomerArticle = $CounterArray;
        }
        $CounterArray++;
    }

    foreach my $ArticleTmp (@ArticleBox) {
        my %Article = %$ArticleTmp;
        if ($LastSenderType ne $Article{SenderType}) {
            $Counter .= "&nbsp;&nbsp;&nbsp;&nbsp;";
            $Space = "$Counter |-->";
        }
        $LastSenderType = $Article{SenderType};
        $ThreadStrg .= "$Space";

        # if this is the shown article 
        if ($ArticleID eq $Article{ArticleID} ||
                 (!$ArticleID && $LastCustomerArticleID eq $Article{ArticleID})) {
            $ThreadStrg .= ">><B>";
        }

        # the full thread string
        $ThreadStrg .= "<A HREF=\"$BaseLink&Action=AgentZoom&ArticleID=$Article{ArticleID}\">" .
        "$Article{SenderType} ($Article{ArticleType})</A> ";
        if ($Article{ArticleType} =~ /^email/) {
            $ThreadStrg .= " (<A HREF=\"$BaseLink&Action=AgentPlain&ArticleID=$Article{ArticleID}\">" .
            $Self->{LanguageObject}->Get('plain') . "</A>)";
        }
        $ThreadStrg .= " $Article{CreateTime}";
        $ThreadStrg .= "<BR>";

        # if this is the shown article
        if ($ArticleID eq $Article{ArticleID} ||
                 (!$ArticleID && $LastCustomerArticleID eq $Article{ArticleID})) {
            $ThreadStrg .= "</B>";
        }
    }
    $ThreadStrg .= '</FONT>';
    $Param{ArticleStrg} .= $ThreadStrg;

    my $ArticleOB = $ArticleBox[$LastCustomerArticle];
    my %Article = %$ArticleOB;

    my $ArticleArray = 0;
    foreach my $ArticleTmp (@ArticleBox) {
        my %ArticleTmp1 = %$ArticleTmp;
        if ($ArticleID eq $ArticleTmp1{ArticleID}) {
            %Article = %ArticleTmp1;
        }
    }
    # --
    # get aatm strg
    # --
    my $ATMsTmp = $Article{Atms};
    my @ATMs = ();
    @ATMs = @$ATMsTmp if ($ATMsTmp);
    my $ATMStrg = '';
    # FIXME!!! filename and html quoting!!!
    foreach (@ATMs) {
        $Param{"Article::ATM"} .= '<a href="$Env{"Baselink"}&Action=AgentAttachment&'.
          'ArticleID='.$Article{ArticleID}.'&File='.$_.'">'. $_ .'</a><br> ';
    }
    # --
    # do some strips && quoting
    # --
    foreach ('To', 'Cc', 'From', 'Subject') {
        $Param{"Article::$_"} = $Self->Ascii2Html(Text => $Article{$_}, Max => 300, MIME => 1);
    }
    # --
    # html quoting
    # --
    $Param{"Article::Text"} = $Self->Ascii2Html(
        NewLine => $Self->{ConfigObject}->Get('ViewableTicketNewLine') || 85,
        Text => $Article{Text},
        VMax => $Self->{ConfigObject}->Get('ViewableTicketLinesZoom') || 5000,
    );
    # --
    # link quoting
    # --
    $Param{"Article::Text"} = $Self->LinkQuote(
        Text => $Param{"Article::Text"},
    );

    # get article id
    $Param{"Article::ArticleID"} = $Article{ArticleID};

    # select the output template
    my $Output = '';
    if ($Article{ArticleType} =~ /^note/i || 
         ($Article{ArticleType} =~ /^phone/i && $Article{SenderType} eq 'agent')) {
        # without compose links and with From ans Subject only!
        $Output = $Self->Output(TemplateFile => 'TicketZoomNote', Data => \%Param);
    }
    elsif ($Article{SenderType} eq 'system' || $Article{SenderType} eq 'agent') {
        # without compose links!
        $Output = $Self->Output(TemplateFile => 'TicketZoomSystem', Data => \%Param);
    }
    else {
        # without all!
        $Output = $Self->Output(TemplateFile => 'TicketZoom', Data => \%Param);
    }

    # return output
    return $Output;
}
# --
sub ArticlePlain {
    my $Self = shift;
    my %Param = @_;

    # Ascii2Html
    $Param{Text} = $Self->Ascii2Html(Text => $Param{Text});

    # do some highlightings
    $Param{Text} =~ s/^((From|To|Cc|Subject|Reply-To|Organization|X-Company):.*)/<font color=\"red\">$1<\/font>/gm;
    $Param{Text} =~ s/^(Date:.*)/<FONT COLOR=777777>$1<\/font>/m;
    $Param{Text} =~ s/^((X-Mailer|User-Agent|X-OS):.*(Mozilla|Win?|Outlook|Microsoft|Internet Mail Service).*)/<blink>$1<\/blink>/gmi;
    $Param{Text} =~ s/(^|^<blink>)((X-Mailer|User-Agent|X-OS|X-Operating-System):.*)/<font color=\"blue\">$1$2<\/font>/gmi;
    $Param{Text} =~ s/^((Resent-.*):.*)/<font color=\"green\">$1<\/font>/gmi;
    $Param{Text} =~ s/^(From .*)/<font color=\"gray\">$1<\/font>/gm;
    $Param{Text} =~ s/^(X-OTRS.*)/<font color=\"#99BBDD\">$1<\/font>/gmi;

    # create & return output
    return $Self->Output(TemplateFile => 'AgentPlain', Data => \%Param);
}
# --
sub Note {
    my $Self = shift;
    my %Param = @_;

    # build ArticleTypeID string
    $Param{'NoteStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NoteTypes},
        Name => 'NoteID',
    );

    # get output back
    return $Self->Output(TemplateFile => 'AgentNote', Data => \%Param);
}
# --
sub AgentPhone {
    my $Self = shift;
    my %Param = @_;

    # build ArticleTypeID string
    $Param{'NoteStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NoteTypes},
        Name => 'NoteID',
#        Selected => $Self->{ConfigObject}->Get('DefaultPhoneNoteType'),
    );

    # build next states string
    $Param{'NextStatesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NextStates},
        Name => 'NextStateID',
        Selected => $Self->{ConfigObject}->Get('DefaultPhoneNextState'),
    );

    # get output back
    return $Self->Output(TemplateFile => 'AgentPhone', Data => \%Param);
}
# --
sub AgentPhoneNew {
    my $Self = shift;
    my %Param = @_;

    # build next states string
    $Param{'NextStatesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NextStates},
        Name => 'NextStateID',
        Selected => $Self->{ConfigObject}->Get('DefaultPhoneNewNextState'),
    );

    $Param{'ToStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{To},
        Name => 'NewQueueID',
#        Selected => $Self->{ConfigObject}->Get('DefaultPhoneNextState'),
    );


    # get output back
    return $Self->Output(TemplateFile => 'AgentPhoneNew', Data => \%Param);
}
# --
sub AgentPriority {
    my $Self = shift;
    my %Param = @_;

    # build ArticleTypeID string
    $Param{'OptionStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{OptionStrg},
        Name => 'PriorityID'
    );

    # create & return output
    return $Self->Output(TemplateFile => 'AgentPriority', Data => \%Param);
}
# --
sub AgentOwner {
    my $Self = shift;
    my %Param = @_;

    # build string
    $Param{'OptionStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{OptionStrg},
        Selected => $Param{OwnerID},
        Name => 'NewUserID', 
        Size => 15,
    );

    # create & return output
    return $Self->Output(TemplateFile => 'AgentOwner', Data => \%Param);
}
# --
sub AgentClose {
    my $Self = shift;
    my %Param = @_;

    # build string
    $Param{'NextStatesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NextStatesStrg},
        Name => 'CloseStateID'
    );
    # build string
    $Param{'NoteTypesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NoteTypesStrg},
        Name => 'CloseNoteID'
    );
    # create & return output
    return $Self->Output(TemplateFile => 'AgentClose', Data => \%Param);
}
# --
sub AgentUtilForm {
    my $Self = shift;
    my %Param = @_;
    # create & return output
    return $Self->Output(TemplateFile => 'AgentUtilForm', Data => \%Param);
}
# --
sub AgentUtilSearchAgain {
    my $Self = shift;
    my %Param = @_;
    # create & return output
    return $Self->Output(TemplateFile => 'AgentUtilSearchAgain', Data => \%Param);
}
# --
sub AgentUtilSearchResult {
    my $Self = shift;
    my %Param = @_;
    my $Highlight = $Param{Highlight} || 0;
    my $HighlightStart = '<font color="orange"><b><i>';
    my $HighlightEnd = '</i></b></font>';

    $Self->{UtilSearchResultCounter}++;

    $Param{Age} = $Self->CustomerAge(Age => $Param{Age}, Space => ' ') || 0;

    # do some strips
    $Param{Text} =~ s/^\s*\n//mg;
    $Param{Text} = $Self->Ascii2Html(
        Text => $Param{Text},
        NewLine => $Self->{ConfigObject}->Get('ViewableTicketNewLine') || 85,
        VMax => $Self->{ConfigObject}->Get('ViewableTicketLinesBySearch') || 15,
      );

    if ($Highlight) {
        # do some html highlighting
        my @SParts = split('%', $Param{What});
        $Param{Text} =~ s/(${\(join('|', @SParts))})/$HighlightStart$1$HighlightEnd/gi;
        $Param{From} =~ s/(${\(join('|', @SParts))})/$HighlightStart$1$HighlightEnd/gi;
        $Param{Subject} =~ s/(${\(join('|', @SParts))})/$HighlightStart$1$HighlightEnd/gi;
    }

    # create & return output
    return $Self->Output(TemplateFile => 'AgentUtilSearchResult', Data => \%Param);
}
# --
sub AgentUtilSearchCouter {
    my $Self = shift;
    my %Param = @_;
    my $Limit = $Param{Limit} || 0;
    my $Output = '';
    $Self->{UtilSearchResultCounter} = 0 if (!$Self->{UtilSearchResultCounter});
    if ($Limit == $Self->{UtilSearchResultCounter}) {
    $Output = "<B>${\$Self->{LanguageObject}->Get('Total hits')}: &gt;<FONT COLOR=RED>" .
    $Self->{UtilSearchResultCounter} . "</FONT></B><BR>";
    }
    else {
    $Output = "<B>${\$Self->{LanguageObject}->Get('Total hits')}: $Self->{UtilSearchResultCounter}</B><BR>";
    }
    return $Output;
}
# --
sub AgentCompose {
    my $Self = shift;
    my %Param = @_;

    # build next states string
    $Param{'NextStatesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NextStates},
        Name => 'ComposeStateID'
    );

    # prepare 
    foreach ('ReplyTo', 'To', 'Cc', 'Subject') {
        $Param{$_} = $Self->MimeWordDecode(Text => $Param{$_}) || '';
        $Param{$_} =~ s/"//g;
    }
    $Param{FromHTML} = $Self->Ascii2Html(Text => $Param{From}, Max => 70, MIME => 1);

    # create & return output
    return $Self->Output(TemplateFile => 'AgentCompose', Data => \%Param);
}
# --
sub AgentForward {
    my $Self = shift;
    my %Param = @_;

    # build next states string
    $Param{'NextStatesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{NextStates},
        Name => 'ComposeStateID'
    );

    $Param{'ArticleTypesStrg'} = $Self->OptionStrgHashRef(
        Data => $Param{ArticleTypes},
        Name => 'ArticleTypeID'
    );


    foreach ('ReplyTo', 'To', 'Cc', 'Subject') {
        $Param{$_} = $Self->MimeWordDecode(Text => $Param{$_}) || '';
        $Param{$_} =~ s/"//g;
    }
    $Param{SystemFromHTML} = $Self->Ascii2Html(Text => $Param{SystemFrom}, Max => 70, MIME => 1);

    # create & return output
    return $Self->Output(TemplateFile => 'AgentForward', Data => \%Param);
}
# --
sub AgentPreferencesForm {
    my $Self = shift;
    my %Param = @_;

    # build option string
    $Param{LanguageOption} = $Self->OptionStrgHashRef(
        Data => {
          $Self->{DBObject}->GetTableData(
            What => 'language, language',
            Valid => 1,
            Clamp => 0,
            Table => 'language',
          )
        },
        Name => 'GenericTopic',
        Selected => $Self->{UserLanguage},
    );

    $Param{'CharsetOption'} = $Self->OptionStrgHashRef(
        Data => {
          $Self->{DBObject}->GetTableData(
            What => 'charset, charset',
            Table => 'charset',
            Valid => 1,
          )
        },
        Name => 'GenericTopic',
        Selected => $Self->{UserCharset},
    );

    $Param{'ThemeOption'} = $Self->OptionStrgHashRef(
        Data => {
          $Self->{DBObject}->GetTableData(
            What => 'theme, theme',
            Table => 'theme',
            Valid => 1,
          )
        },
        Name => 'GenericTopic',
        Selected => $Self->{UserTheme},
    );

    $Param{'RefreshOption'} = $Self->OptionStrgHashRef(
        Data => $Self->{ConfigObject}->Get('RefreshOptions'),
        Name => 'GenericTopic',
        Selected => $Self->{UserRefreshTime},
    );

    $Param{'SendFollowUpNotificationYesNoOption'} = $Self->OptionStrgHashRef(
        Data => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name => 'GenericTopic',
        SelectedID => $Self->{UserSendFollowUpNotification},
    );

    $Param{'SendNewTicketNotificationYesNoOption'} = $Self->OptionStrgHashRef(
        Data => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name => 'GenericTopic',
        SelectedID => $Self->{UserSendNewTicketNotification},
    );


    my @CustomQueueIDs = $Self->{QueueObject}->GetAllCustomQueues(UserID => $Self->{UserID});
    # prepar custom selection
    my $CustomQueueIDs = $Param{CustomQueueIDs};
    my @CustomQueueIDsTmp = @$CustomQueueIDs;
    my $QueueData = $Param{QueueData};
    my %QueueDataTmp = %$QueueData;
    $Param{QueueDataStrg} = '';
    foreach my $ID (sort keys %QueueDataTmp) {
        my $Mach = 0;
        foreach (@CustomQueueIDsTmp) {
            if ($_ eq $ID) {
                $Param{QueueDataStrg} .= "<OPTION selected VALUE=\"$ID\">$QueueDataTmp{$ID}\n";
                $Mach = 1;
            }
         }
         $Param{QueueDataStrg} .= "<OPTION VALUE=\"$ID\">$QueueDataTmp{$ID}\n" if (!$Mach);
    }


    # create & return output
    return $Self->Output(TemplateFile => 'AgentPreferencesForm', Data => \%Param);
}
# --
sub AgentMailboxTicket {
    my $Self = shift;
    my %Param = @_;

    if ($Param{ViewType} eq 'New' && $Param{LastSenderID} eq $Param{UserID}) {
        return;
    }
    
    if ($Param{LastSenderID} ne $Param{UserID}) {
        $Param{Message} = 'New message!';
    }

    $Param{Age} = $Self->CustomerAge(Age => $Param{Age}, Space => ' ');

    # do some strips && quoting
    foreach ('To', 'Cc', 'From', 'Subject') {
        $Param{$_} = $Self->Ascii2Html(Text => $Param{$_}, Max => 70, MIME => 1);
    }

    # create & return output
    return $Self->Output(TemplateFile => 'AgentMailboxTicket', Data => \%Param);
}
# --
sub AgentHistory {
    my $Self = shift;
    my %Param = @_;

    my $BackScreen = $Param{BackScreen} || '';
    my $LinesTmp = $Param{Data};
    my @Lines = @$LinesTmp;
    my $Output = '';

    foreach my $Data (@Lines) {
      # html qouting
      foreach ('Name', 'HistoryType', 'CreateBy', 'CreateTime') {
        $$Data{$_} = $Self->Ascii2Html(Text => $$Data{$_});
      }
      # get html string
      $Param{History} .= $Self->Output(TemplateFile => 'AgentHistoryRow', Data => $Data);
    }

    # create & return output
    return $Self->Output(TemplateFile => 'AgentHistoryForm', Data => \%Param);
}
# --
sub TicketLocked {
    my $Self = shift;
    my %Param = @_;
    return $Self->Output(TemplateFile => 'AgentTicketLocked', Data => \%Param);
}
# --
sub Attachment {
    my $Self = shift;
    my %Param = @_;
   (my $Output = <<EOF);
Content-Disposition: attachment; filename=$Param{File}
Content-Type: $Param{Type}
$Param{Data}
EOF
    return $Output;
}
# --

1;
 
