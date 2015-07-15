function showMessageOfTheDay() {
  d3.html("/message-of-the-day.html", messageOfTheDayLoaded);

  function messageOfTheDayLoaded(message) {
    var body = d3.select("body").node();
    body.insertBefore(message, body.firstChild);
  }
}

document.addEventListener('DOMContentLoaded',showMessageOfTheDay);
