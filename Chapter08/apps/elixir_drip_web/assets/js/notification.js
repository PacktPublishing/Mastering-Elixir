let Notification = {
  init(socket, userId) {
    let infoArea = document.getElementById("notify_info")
    let successArea = document.getElementById("notify_success")
    let userChannel = socket.channel("users:" + userId)

    let share_button = document.getElementById("share_file_btn")
    if (share_button != null) {
      share_button.onclick = () => { this.sharePopUp(userChannel) }
    }

    userChannel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", reason => { console.log("Unable to join", reason) })

    userChannel.on("upload", ({message}) => this.renderNotifcation(infoArea, successArea, message))
    userChannel.on("download", ({message, link}) => this.renderDownloadNotifcation(infoArea, successArea, message, link))
    userChannel.on("share", ({message}) => this.renderNotifcation(infoArea, successArea, message))
  },

  renderNotifcation(infoArea, successArea, message) {
    infoArea.innerHTML = ""
    successArea.innerHTML = message
  },

  renderDownloadNotifcation(infoArea, successArea, message, link) {
    infoArea.innerHTML = ""
    successArea.innerHTML = `<a href="${link}">${message}</a>`
  },

  sharePopUp(userChannel) {
    let username = prompt("Share file with:", "username")
    if (username != null && username != "") {
      let splitUrl = window.location.href.split('/')
      let fileId = splitUrl.pop() || splitUrl.pop()

      userChannel.push("share", {username: username, file_id: fileId})
    }
  }
}

export default Notification
