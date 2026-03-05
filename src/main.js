import "primeicons/primeicons.css";
import "./style.css";

import { createApp } from "vue";
import { createPinia } from "pinia";
import PrimeVue from "primevue/config";
import ToastService from "primevue/toastservice";
import ConfirmationService from 'primevue/confirmationservice';

// PrimeVue Components
import Tree from 'primevue/tree';
import ContextMenu from 'primevue/contextmenu';
import Button from 'primevue/button';
import SplitButton from 'primevue/splitbutton';
import Dialog from 'primevue/dialog';
import InputText from 'primevue/inputtext';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import Accordion from 'primevue/accordion';
import AccordionPanel from 'primevue/accordionpanel';
import AccordionHeader from 'primevue/accordionheader';
import AccordionContent from 'primevue/accordioncontent';
import Badge from 'primevue/badge';
import ProgressBar from 'primevue/progressbar';

import App from "./App.vue";
import Noir from './presets/Noir.js';

const pinia = createPinia();
const app = createApp(App);

app.use(pinia);
app.use(PrimeVue, {
    theme: {
        preset: Noir,
        options: {
            prefix: 'p',
            darkModeSelector: '.p-dark',
            cssLayer: false,
        }
    }
});

app.use(ToastService);
app.use(ConfirmationService);

// Register PrimeVue Components
app.component('Tree', Tree);
app.component('ContextMenu', ContextMenu);
app.component('Button', Button);
app.component('SplitButton', SplitButton);
app.component('Dialog', Dialog);
app.component('InputText', InputText);
app.component('IconField', IconField);
app.component('InputIcon', InputIcon);
app.component('Accordion', Accordion);
app.component('AccordionPanel', AccordionPanel);
app.component('AccordionHeader', AccordionHeader);
app.component('AccordionContent', AccordionContent);
app.component('Badge', Badge);
app.component('ProgressBar', ProgressBar);

app.mount("#app");
