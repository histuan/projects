const button = document.querySelectorAll(".faq-button");

button.forEach((button) =>{
  button.addEventListener("click", ()=>{
    button.closest(".faq-item").classList.toggle("active");
  })
})