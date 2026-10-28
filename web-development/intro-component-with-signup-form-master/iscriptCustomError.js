const user = document.querySelectorAll(".name");
const email = document.querySelector(".email");
const password = document.querySelector(".password");
const form = document.querySelector("form");

form.addEventListener('submit',(e)=>{
  e.preventDefault();

  user.forEach((name)=>{
    if(name.value.trim() == "") showError(name.parentElement,2);
  })
  if(email.value.trim() == "") showError(email.parentElement,2);
  if(password.value.trim() == "") showError(password.parentElement,2);
})

user.forEach((name)=>{
  name.addEventListener('input',(e)=>{
    if(e.target.value.length > 0 && /[^\p{L} \s]/u.test(e.target.value)){
      showError(e.target.parentElement, 1);
      removeError(e.target.parentElement, 2);
    } else {
      removeError(e.target.parentElement, 1);
      removeError(e.target.parentElement, 2);
    }
  })
})

email.addEventListener('input', (e)=>{
  if(e.target.value.length > 0 && !/\S+@\S+\.\S+/.test(e.target.value)){
    showError(e.target.parentElement, 1);
    removeError(e.target.parentElement, 2);
  } else {
    removeError(e.target.parentElement,1);
    removeError(e.target.parentElement, 2);
  }
})

password.addEventListener('input', (e)=>{
  if(e.target.value.length > 0 && e.target.value.length < e.target.minLength){
    showError(e.target.parentElement,1);
    e.target.parentElement.children[1].textContent = "Your password must have at least 6 characters. " + (e.target.value.length)
    removeError(e.target.parentElement,2);
  } else {
    removeError(e.target.parentElement,1);
    removeError(e.target.parentElement,2);
  }
})

function showError(input, n){
  input.children[n].classList.add("active");
}
function removeError(input, n){
  input.children[n].classList.remove("active")
}
