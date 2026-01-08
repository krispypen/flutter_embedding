import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { FlutterEmbedding } from '{{webAngularPackageName}}';
import { AppModule } from './app/app.module';

FlutterEmbedding.startEngine().catch((error: any) => {
  console.error('Failed to start Flutter engine:', error);
});

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .catch((err) => console.error(err));

