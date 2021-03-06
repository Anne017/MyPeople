import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Layouts 1.0

/* replace the 'incomplete' QML API U1db with the low-level QtQuick API */
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.ListItems 1.3 as ListItem

import "../../js/storage.js" as Storage
import "../../js/DateUtils.js" as DateUtils

 /*
    Item that display a meeting item retrieved from the database.
    Used to diplay the search result for meetings with ANY people
    (Note: a delegate object can access directly ath values in the dataModel)
 */
 Item {
        id: allPeopleMeetingFoundDelegate

        property string todayDateFormatted : DateUtils.formatFullDateToString(new Date());
        /* workaround to specify the origin page: todaMeeting or SearchMeeting. FIXME: find better solution  */
        property bool isFromTodayMeetingPage: false;   //isFromGlobalMeetingSearch

        width: parent.width
        height: units.gu(13) /* the heigth of the rectangle that contains an meeting in the list */

        /* container for each meeting */
        Rectangle {
            id: background
            x: 2;
            y: 2;
            width: parent.width - x*2;
            height: parent.height - y*1
            border.color: "black"
            radius: 5
        }

        Component {
            id: confirmDeleteMeetingComponent
            Dialog {
                id: confirmDeleteMeeting
                title: i18n.tr("Confirmation")
                modal:true
                text: i18n.tr("Delete selected Meeting ?")

                Label{
                    id: operationResultLabel
                    text: ""
                    color: UbuntuColors.green
                }

                Button {
                    text: i18n.tr("Close")
                    onClicked: {
                        /* update */
                        Storage.getTodayMeetings();

                        /* to refresh repeat the same user search */
                        Storage.searchMeetingByTimeRange(searchAnyMeetingPage.dateFrom,searchAnyMeetingPage.dateTo,searchAnyMeetingPage.meetingStatus);

                        PopupUtils.close(confirmDeleteMeeting)
                    }
                }

                Button {
                    id:executeButton
                    text: i18n.tr("Execute")  //Delete

                    onClicked: {

                        var meetingId;
                        /* depending on the source page, pick-up the meetingId from a different UbuntuListView */
                        if(isFromTodayMeetingPage === true){
                           meetingId = todayMeetingModel.get(todayMeetingResultList.currentIndex).id;
                        }else{
                           /* the 'id' of the currently selected meeting */
                           meetingId = allPeopleMeetingFoundModel.get(allPeopleMeetingSearchResultList.currentIndex).id;
                        }

                        Storage.deleteMeetingById(meetingId);

                        operationResultLabel.text = i18n.tr("Operation executed successfully")
                        executeButton.enabled = false;
                    }
                }
            }
        }

        Component {
            id: confirmArchiveMeetingComponent

            Dialog {
                id: confirmArchiveMeeting
                title: i18n.tr("Confirmation")
                modal:true
                contentWidth: units.gu(47)

                Text {
                    anchors.horizontalCenter: parent.Center
                    text: "<b>"+ i18n.tr("Mark as 'ARCHIVED' and leave it in the database ?")  +"</b><br/>"
                                +"<br/>"+i18n.tr("(if you archive a meeting you can reuse it")+"<br/>"
                                +i18n.tr("in the future simply updating it)")

                }

                Label{
                    id: operationResultLabel
                    text: ""
                    color: UbuntuColors.green
                }

                Row{
                    spacing: units.gu(1)
                    x: units.gu(5)

                    Button {
                        text: i18n.tr("Close")
                        width: units.gu(14)
                        onClicked: {

                            if(isFromTodayMeetingPage === true){
                               Storage.getTodayMeetings();
                            }

                            /* refresh re-executong the search */
                            Storage.searchMeetingByTimeRange(searchAnyMeetingPage.dateFrom,searchAnyMeetingPage.dateTo,searchAnyMeetingPage.meetingStatus);

                            PopupUtils.close(confirmArchiveMeeting)
                        }
                    }

                    Button {
                        id:executeButton
                        width: units.gu(14)
                        text: i18n.tr("Execute") //ARCHIVE

                        onClicked: {

                            var meetingId;
                            /* depending on the source page, pick-up the meetingId from a different UbuntuListView */
                            if(isFromTodayMeetingPage === true){
                               meetingId = todayMeetingModel.get(todayMeetingResultList.currentIndex).id;
                            }else{
                               /* the 'id' of the selected meeting */
                               meetingId = allPeopleMeetingFoundModel.get(allPeopleMeetingSearchResultList.currentIndex).id;
                            }

                            Storage.updateMeetingStatus(meetingId,"ARCHIVED");

                            operationResultLabel.text = i18n.tr("Operation executed successfully")
                            executeButton.enabled = false;
                        }
                    }
                }
            }
        }

        /* This mouse region covers the entire delegate */
        MouseArea {
            id: selectableMouseArea
            anchors.fill: parent
            onClicked: {

                 if(isFromTodayMeetingPage === true){
                    todayMeetingResultList.currentIndex = index
                 }else{
                    /* move the highlight component to the currently selected item */
                    allPeopleMeetingSearchResultList.currentIndex = index
                }
            }
        }

        /* create a row for each entry in the Model */
        Row {
            id: topLayout
            x: 10;
            y: 10;
            height: background.height;
            width: parent.width
            spacing: units.gu(0.5)

            Column {
                width: background.width - 10 - editMeetingColumn.width;
                height: allPeopleMeetingFoundDelegate.height
                spacing: units.gu(0.2)

                Label {
                      text: "<b>"+i18n.tr("Name")+": "+"</b>"+name +"   <b>"+i18n.tr("Surname")+": </b>"+ surname
                      fontSize: "medium"
                }

                Label {
                    text: "<b>"+i18n.tr("Date")+"(yyyy-mm-dd): </b>"+date.split(' ')[0] + "  <b>"+i18n.tr("Time")+": </b>"+date.split(' ')[1]
                    fontSize: "medium"
                }

                Label {
                    text: "<b>"+i18n.tr("Place")+": </b>"+place
                    fontSize: "medium"
                }

                Label {
                    text: "<b>"+i18n.tr("Subject")+": </b>"+subject
                    fontSize: "medium"
                }

                Label {
                    id: meetingStatusLabel
                    text: "<b>"+i18n.tr("Meeting status")+": </b>"+"<b>"+status+"</b>"
                    fontSize: "medium"
                    color: "grey"
                }

                Component.onCompleted: {

                    /* if a meeting with status TODO and date greater than now is notified as expired */
                    if(date < todayDateFormatted && status !== i18n.tr("ARCHIVED")) {
                       meetingStatusLabel.text =  meetingStatusLabel.text + " "+i18n.tr("(EXPIRED)")
                       meetingStatusLabel.color = "orange"
                    }
                }
            }

            Column{
                id: editMeetingColumn
                width: units.gu(5)
                anchors.verticalCenter: topLayout.verticalCenter
                spacing: units.gu(1)

                Row{
                    /* note: use Icon Object insted of Image to access at sytem default icon without specify a full path to image */
                    Icon {
                        id: editMeetingIcon
                        width: units.gu(3)
                        height: units.gu(3)
                        name: "edit"

                        MouseArea {
                            width: editMeetingIcon.width
                            height: editMeetingIcon.height
                            onClicked: {

                                adaptivePageLayout.addPageToNextColumn(searchAnyMeetingPage,Qt.resolvedUrl("EditMeetingPage.qml") ,
                                                                       {
                                                                          /* <page-variable-name>:<property-value-to-pass> */
                                                                          id:id,
                                                                          name:name,
                                                                          surname:surname,
                                                                          subject:subject,
                                                                          date:date,
                                                                          place:place,
                                                                          status: meetingStatusLabel.text,
                                                                          note:note,
                                                                          isFromGlobalMeetingSearch:true
                                                                          //dateFrom:dateFrom,
                                                                          //dateTo:dateTo,
                                                                          //meetingStatus:meetingStatus
                                                                        }
                                                                       )

                             }
                        }
                    }
                }

                Row{
                    Icon {
                         id: deleteMeetingIcon
                         width: units.gu(3)
                         height: units.gu(3)
                         name: "delete"

                         MouseArea {
                              width: deleteMeetingIcon.width
                              height: deleteMeetingIcon.height
                              onClicked: {
                                 PopupUtils.open(confirmDeleteMeetingComponent);
                              }
                         }
                      }
                }

                Row{
                    id: archiveMeetingRow
                    Icon {
                         id: archiveMeetingIcon
                         width: units.gu(3)
                         height: units.gu(3)
                         name: "ok"

                         MouseArea {
                              width: archiveMeetingIcon.width
                              height: archiveMeetingIcon.height
                              onClicked: {
                                 PopupUtils.open(confirmArchiveMeetingComponent);
                              }
                         }
                     }
                     /* if the meeting is already marked as ARCHIVED hide the icons */
                     Component.onCompleted: {
                          if (status ===i18n.tr("ARCHIVED")){
                              archiveMeetingRow.visible = false
                         }
                     }
                }

            }
        }
    }
