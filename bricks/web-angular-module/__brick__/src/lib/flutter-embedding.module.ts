//{{=<% %>=}}
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FlutterEmbeddingViewComponent } from './flutter-embedding-view.component';
import { FlutterEmbeddingService } from './flutter-embedding.service';

@NgModule({
    declarations: [],
    imports: [
        CommonModule,
        FlutterEmbeddingViewComponent
    ],
    exports: [
        FlutterEmbeddingViewComponent
    ],
    providers: [
        FlutterEmbeddingService
    ]
})
export class FlutterEmbeddingModule { }

