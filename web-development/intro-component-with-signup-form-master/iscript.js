const user = document.querySelectorAll(".name");
const email = document.querySelector(".email");

user.forEach((name)=>{

  name.addEventListener('input', (e) => {

    e.target.setCustomValidity('');
  });

  name.addEventListener('blur', (e)=>{

    if(e.target.value.length > 0 && /[^\p{L}\s]/u.test(e.target.value)){
      e.target.setCustomValidity("Type a valid name!");
      e.target.reportValidity();
    } else {
      setTimeout(()=>{e.target.setCustomValidity('')}, 1);
    }
  });
})

email.addEventListener('input',(e)=>{
  e.target.setCustomValidity(' ');

})
email.addEventListener('blur',(e)=>{
  if(e.target.value.length > 0 && !e.target.checkValidity()){
    e.target.setCustomValidity('');
    e.target.reportValidity();
  } else {
    setTimeout(()=>{e.target.setCustomValidity('')},1);
  }
})