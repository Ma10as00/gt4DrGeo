Class {
	#name : #DGSketchElement,
	#superclass : #BlElement,
	#instVars : [
		'sketch',
		'mathItemDict',
		'showBorder'
	],
	#category : #'Gt4DrGeo-View'
}

{ #category : #'instance creation' }
DGSketchElement class >> for: aSketch [
	^ self new
		sketch: aSketch;
		yourself
]

{ #category : #'children - add/remove' }
DGSketchElement >> addChild: aMathItemElement [
	super addChild: aMathItemElement.
	aMathItemElement idWithIndex: children size.
	self assert: aMathItemElement isMathItemElement.
	mathItemDict at: aMathItemElement mathItem ifAbsentPut: aMathItemElement
]

{ #category : #conversion }
DGSketchElement >> asPinchable [
	| element |
	element := BlPinchableElement new
			zoomLevel: 2;
			clipChildren: false;
			contentElement: self;
			id: self sketchPinchableId;
			yourself.
	self showBorder ifTrue: [ element border: (BlBorder paint: Color lightGray) ].
	^ element
]

{ #category : #conversion }
DGSketchElement >> asPinchablePannable [
	| sketchPannable sketchPinchable |
	sketchPinchable := self asPinchable.
	sketchPannable := sketchPinchable asPannableElement
			padding: (BlInsets all: self padding);
			margin: (BlInsets all: self margin);
			id: self sketchPannableId;
			aptitude: (BrGlamorousWithContextMenuAptitude
					content: [ BrGlamorousSimpleContextMenuContent new
							items: {'Inspect graph' -> [ self inspect ]};
							yourself ]);
			yourself.
	self showBorder
		ifTrue: [ sketchPannable border: (BlBorder paint: Color orange) ].
	^ sketchPannable
]

{ #category : #initialization }
DGSketchElement >> defaultShowBorder [
	^ false
]

{ #category : #example }
DGSketchElement >> demo [
	<gtExample>
	^ self class new asPinchablePannable
]

{ #category : #accessing }
DGSketchElement >> elementForItem: aMathItem [
	"Should not fail. If it does, we can add a moldable exception ...
	NB: We need an IdentityDictionary so we can find  items even if their value changes!"

	^ mathItemDict
		at: aMathItem
		ifAbsent: [ self error: 'Cannot find this element' ]
]

{ #category : #view }
DGSketchElement >> gtLiveFor: aView [
	<gtView>
	^ aView forward
		title: 'Live';
		priority: 0;
		object: [ self asPinchablePannable ];
		view: #gtLiveFor:
]

{ #category : #initialization }
DGSketchElement >> initialize [
	super initialize.
	showBorder := self defaultShowBorder.
	mathItemDict := IdentityDictionary new.
	self initializeLayout.
	self id: DGSketchElementId
]

{ #category : #initialization }
DGSketchElement >> initializeLayout [
	self
		layout: (BlWrapAroundChildrenLayout new addLayout: BlBasicNodeBasedLayout new);
		constraintsDo: [ :c | 
			c horizontal fitContent.
			c vertical fitContent ];
		padding: (BlInsets all: self padding);
		margin: (BlInsets all: self margin).
	self showBorder
		ifTrue: [ self
				background: Color white;
				effect: BrGlamorousShadowEffect new ]
]

{ #category : #demo }
DGSketchElement >> makeNode [
	"For now, just here for demo purposes. To be replaced."

	| makeNode |
	makeNode := [ | node |
		node := BlElement new.
		node
			layout: BlFrameLayout new;
			geometry: (BlRoundedRectangleGeometry cornerRadius: 4);
			background: Color white;
			constraintsDo: [ :c | 
				c horizontal fitContent.
				c vertical fitContent ];
			padding: (BlInsets all: 10).
		node graph beNode.
		node
			aptitude: (BrStyleCommonAptitude new
					default: [ :aStyle | aStyle border: (BlBorder paint: Color black width: 1) ];
					hovered: [ :aStyle | aStyle border: (BlBorder paint: Color red width: 1) ])
					+ ((BrGlamorousWithContextMenuAptitude
							content: [ BrGlamorousSimpleContextMenuContent new
									items: {'Inspect node' -> [ node inspect ]};
									yourself ])
							useSecondaryMouseButton;
							yourself).
		node addEventHandler: BlPullHandler new.
		node
			addEventHandler: (BlEventHandler
					on: BlDoubleClickEvent
					do: [ :evt | 
						evt consumed: true.
						node phlow spawnObject: node ]).
		node ] asStencil.
	^ makeNode
]

{ #category : #constant }
DGSketchElement >> margin [
	| margin |
	margin := self padding.
	^ margin
]

{ #category : #querying }
DGSketchElement >> newItems [
	"These are the new items added to the sketch since the last update."

	^ sketch mathItems reject: [ :item | mathItemDict includesKey: item ]
]

{ #category : #constant }
DGSketchElement >> padding [
	| padding |
	padding := 2.
	^ padding
]

{ #category : #playing }
DGSketchElement >> playNewItems [
	"Here we need to populate the Sketch element with elements representing the mathItems of the sketch."
	^ self newItems do: [ :item | item playIn: self ]
]

{ #category : #accessing }
DGSketchElement >> pointElements [
	^ self children select: #isDGPointElement
]

{ #category : #accessing }
DGSketchElement >> showBorder [
	^ showBorder
]

{ #category : #accessing }
DGSketchElement >> showBorder: anObject [
	showBorder := anObject
]

{ #category : #accessing }
DGSketchElement >> sketch [
	^ sketch
]

{ #category : #accessing }
DGSketchElement >> sketch: aSketch [
	sketch := aSketch.
	self playNewItems.
	self subscribeTo: aSketch
]

{ #category : #constant }
DGSketchElement >> sketchPannableId [
	^ '#dg-sketch-pannable'
]

{ #category : #constant }
DGSketchElement >> sketchPinchableId [
	^ '#dg-sketch-pinchable'
]

{ #category : #updating }
DGSketchElement >> subscribeTo: aSketch [
	aSketch announcer
		when: DGMathItemUpdated
		do: [ :a | self updateItem: a mathItem ]
]

{ #category : #updating }
DGSketchElement >> updateItem: aMathItem [
	"Can be used if a point is moved, or if there are new items."

	aMathItem isPointItem ifTrue: [ (self elementForItem: aMathItem) relocate ].	"self pointElements do: #relocate."
	self playNewItems
]
