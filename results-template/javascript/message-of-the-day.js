function showMessageOfTheDay() {
  d3.text("message-of-the-day.html", messageOfTheDayLoaded);

  function messageOfTheDayLoaded(error, message) {
    if(message) {
	    d3.select("body").insert("div",":first-child").html(message);
    }
  }
}

document.addEventListener('DOMContentLoaded',showMessageOfTheDay);
